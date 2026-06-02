# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

require 'json'
require 'fileutils'
require 'logger'
require 'time'
require_relative '../../model/canonical_document'
require_relative '../../model/crossref'
require_relative '../../model/semantic_scholar_paper'
require_relative '../doi_helpers'
require_relative '../semantic_scholar'

module Buhos
  # Validates title and abstract for every canonical document in a review.
  # Missing fields are completed from Crossref and Semantic Scholar when a DOI
  # or Semantic Scholar id is available.
  class ReviewDocumentValidator
    include DOIHelpers

    attr_reader :review, :log_file, :stats, :invalid_documents

    def initialize(review, log_file: nil, logger: nil)
      @review = review
      @log_file = log_file || default_log_file
      @logger = logger || Logger.new(@log_file)
      @stats = Hash.new(0)
      @invalid_documents = []
    end

    def validate
      documents = CanonicalDocument.where(id: review.cd_all_id).order(:id).all
      @stats[:total] = documents.length
      log(:info, "Starting validation for review #{review.id} - #{review.name}")
      log(:info, "Documents to validate: #{documents.length}")

      documents.each do |document|
        validate_document(document)
      end

      log(:info, "Validation finished")
      log(:info, "Summary total=#{stats[:total]} valid=#{stats[:valid]} invalid=#{stats[:invalid]} updated=#{stats[:updated]} crossref_updated=#{stats[:crossref_updated]} semantic_scholar_updated=#{stats[:semantic_scholar_updated]} errors=#{stats[:errors]}")
      self
    ensure
      @logger.close if @logger.respond_to?(:close)
    end

    private

    def default_log_file
      FileUtils.mkdir_p('log')
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      File.join('log', "review_documents_validation_#{review.id}_#{timestamp}.log")
    end

    def validate_document(document)
      before_missing = missing_fields(document)
      if before_missing.empty?
        @stats[:valid] += 1
        log(:info, "cd=#{document.id} status=valid")
        return
      end

      log(:info, "cd=#{document.id} status=incomplete missing=#{before_missing.join(',')}")
      updated_sources = complete_missing_information(document)
      document.refresh
      after_missing = missing_fields(document)

      if updated_sources.any?
        @stats[:updated] += 1
        updated_sources.each { |source| @stats[:"#{source}_updated"] += 1 }
      end

      if after_missing.empty?
        @stats[:valid] += 1
        log(:info, "cd=#{document.id} status=valid_after_update sources=#{updated_sources.join(',')}")
      else
        @stats[:invalid] += 1
        @invalid_documents << { id: document.id, missing: after_missing }
        log(:warn, "cd=#{document.id} status=invalid missing=#{after_missing.join(',')} title=#{document.title.inspect} doi=#{document.doi.inspect} semantic_scholar_id=#{document.semantic_scholar_id.inspect}")
      end
    rescue StandardError => e
      @stats[:errors] += 1
      @stats[:invalid] += 1
      @invalid_documents << { id: document.id, missing: missing_fields(document), error: e.message }
      log(:error, "cd=#{document.id} status=error class=#{e.class} message=#{e.message}")
    end

    def complete_missing_information(document)
      sources = []
      sources << :crossref if complete_from_crossref(document)
      document.refresh
      sources << :semantic_scholar if missing_fields(document).any? && complete_from_semantic_scholar(document)
      sources
    end

    def complete_from_crossref(document)
      return false if document.doi.to_s.strip.empty?

      json_raw = CrossrefDoi.process_doi(document.doi)
      return false unless json_raw

      data = crossref_message(json_raw)
      updates = updates_from_data(document, data)
      document.update(updates) if updates.any?
      log(:info, "cd=#{document.id} source=crossref updated=#{updates.keys.join(',')}")
      updates.any?
    rescue StandardError => e
      @stats[:errors] += 1
      log(:warn, "cd=#{document.id} source=crossref error=#{e.class}: #{e.message}")
      false
    end

    def complete_from_semantic_scholar(document)
      identifier_type, identifier = semantic_identifier(document)
      return false unless identifier

      data = semantic_scholar_data(identifier_type, identifier, document.doi)
      updates = updates_from_data(document, data)
      updates[:semantic_scholar_id] = data['paperId'] if data['paperId'] && document.semantic_scholar_id.to_s.empty?
      document.update(updates) if updates.any?
      log(:info, "cd=#{document.id} source=semantic_scholar updated=#{updates.keys.join(',')}")
      updates.any?
    rescue StandardError => e
      @stats[:errors] += 1
      log(:warn, "cd=#{document.id} source=semantic_scholar error=#{e.class}: #{e.message}")
      false
    end

    def semantic_identifier(document)
      if !document.semantic_scholar_id.to_s.strip.empty?
        [:semantic_scholar_id, document.semantic_scholar_id]
      elsif !document.doi.to_s.strip.empty?
        [:doi, document.doi]
      end
    end

    def semantic_scholar_data(type, identifier, doi)
      cached = Semantic_Scholar_Paper.get(type, identifier)
      return JSON.parse(cached.json) if cached

      remote = SemanticScholar::Remote.new
      json = remote.json_by_id(identifier, type == :semantic_scholar_id ? :s2 : type)
      Semantic_Scholar_Paper.add_from_json(json, doi)
      JSON.parse(json)
    end

    def crossref_message(json_raw)
      parsed = JSON.parse(json_raw)
      parsed = parsed.first if parsed.is_a?(Array)
      parsed.fetch('message', parsed)
    end

    def updates_from_data(document, data)
      updates = {}
      title = first_text(data['title'])
      abstract = first_text(data['abstract'])

      updates[:title] = title if blank?(document.title) && !blank?(title)
      updates[:abstract] = abstract if blank?(document.abstract) && !blank?(abstract)
      updates
    end

    def missing_fields(document)
      missing = []
      missing << :title if blank?(document.title)
      missing << :abstract if blank?(document.abstract)
      missing
    end

    def first_text(value)
      value = value.first if value.is_a?(Array)
      value.to_s.gsub(/\s+/, ' ').strip
    end

    def blank?(value)
      value.to_s.strip.empty?
    end

    def log(level, message)
      @logger.public_send(level, message)
    end
  end
end
