# Copyright (c) 2016-2026, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

require 'date'

require_relative 'result'
require_relative 'bibliographical_importer'
require_relative 'bibliographic_file_processor'

class BibliographicFolderImporter
  BIBLIOGRAPHICAL_DATABASES = [
    'scopus', 'sage', 'wos', 'scielo', 'ebscohost',
    'refworks', 'ieee', 'generic', 'pubmed', 'lilacs',
    'proquest', 'bvs', 'base', 'redalyc'
  ].freeze

  FILETYPES = {
    '.bib' => 'text/x-bibtex',
    '.bibtex' => 'text/x-bibtex',
    '.csv' => 'text/csv',
    '.json' => 'application/json',
    '.nbib' => 'application/nbib',
    '.ris' => 'application/x-research-info-systems'
  }.freeze

  Summary = Struct.new(:path, :search_id, :success, :messages, keyword_init: true)

  attr_reader :folder, :systematic_review_id, :user_id, :result, :summaries

  def initialize(folder, systematic_review_id: nil, user_id: nil, date: Date.today)
    @folder = File.expand_path(folder.to_s)
    @systematic_review_id = systematic_review_id
    @user_id = user_id
    @date = date
    @result = Result.new
    @summaries = []
  end

  def import
    validate_folder!

    files = Dir.glob(File.join(@folder, '**', '*')).select {|path| bibliographic_file?(path) }.sort
    if files.empty?
      @result.warning("No bibliographic files found in #{@folder}")
      return self
    end

    files.each_with_index do |path, index|
      import_file(path, index + 1)
    end

    self
  end

  def success?
    @summaries.any? && @summaries.all?(&:success)
  end

  private

  def validate_folder!
    raise ArgumentError, "Folder is required" if @folder.empty?
    raise ArgumentError, "Folder does not exist: #{@folder}" unless Dir.exist?(@folder)
  end

  def import_file(path, sequence)
    file_result = Result.new
    bibliographic_database_name = bibliographic_database_name_from_filename(path)
    unless bibliographic_database_name
      message = "No bibliographic database name found in #{path}. Expected one of: #{BIBLIOGRAPHICAL_DATABASES.join(', ')}"
      file_result.error(message)
      @result.add_result(file_result)
      @summaries << Summary.new(path: path, search_id: nil, success: false, messages: file_result.message)
      return
    end

    search = create_search(path, sequence)
    content = File.binread(path)
    search.update(file_body: content, filetype: filetype(path), filename: File.basename(path))

    if BibliographicalImporter::Factory.csv_file?(File.basename(path), filetype(path))
      bib_processor = BibliographicalImporter::CSV::SearchBuilder.build(search, file_result)
    else
      bib_processor = BibliographicalImporter::Factory.build(
        content,
        File.basename(path),
        filetype(path),
        file_result
      )
    end

    if bib_processor
      processor = BibliographicFileProcessor.new(search, bib_processor, file_result)
      if processor.error.nil? && file_result.success?
        search.update(valid: true)
        file_result.success("Imported #{path} as search #{search.id}")
        success = true
      else
        search.update(valid: false)
        file_result.error(processor.error) unless processor.error.nil?
        success = false
      end
    else
      search.update(valid: false)
      success = false
    end

    @result.add_result(file_result)
    @summaries << Summary.new(
      path: path,
      search_id: search.id,
      success: success,
      messages: file_result.message
    )
  rescue StandardError => e
    @result.error("#{path}: #{e.class} #{e.message}")
    @summaries << Summary.new(path: path, search_id: nil, success: false, messages: e.message)
  end

  def create_search(path, sequence)
    Search.create(
      systematic_review_id: resolved_systematic_review_id,
      source: 'database_search',
      bibliographic_database_id: bibliographic_database_id_from_filename(path),
      date_creation: @date,
      search_criteria: sequential_name(sequence),
      description: File.expand_path(path),
      search_type: 'bibliographic_file',
      user_id: resolved_user_id,
      valid: false
    )
  end

  def sequential_name(sequence)
    "#{@date.strftime('%Y-%m-%d')}-#{format('%03d', sequence)}"
  end

  def resolved_systematic_review_id
    return @systematic_review_id.to_i if @systematic_review_id

    review_ids = SystematicReview.select_map(:id)
    raise ArgumentError, 'systematic_review_id is required when there is not exactly one systematic review' unless review_ids.length == 1

    review_ids.first
  end

  def resolved_user_id
    return @user_id.to_i if @user_id

    admin = User[:login => 'admin']
    admin ? admin.id : User.order(:id).first.id
  end

  def bibliographic_database_id_from_filename(path)
    database_name = bibliographic_database_name_from_filename(path)
    raise ArgumentError, "No bibliographic database name found in #{path}" unless database_name

    database = BibliographicDatabase[:name => database_name]
    raise ArgumentError, "Bibliographic database '#{database_name}' is not available" unless database

    database.id
  end

  def bibliographic_database_name_from_filename(path)
    filename = File.basename(path).downcase
    BIBLIOGRAPHICAL_DATABASES.find do |database_name|
      filename =~ /(^|[^a-z0-9])#{Regexp.escape(database_name)}([^a-z0-9]|$)/
    end
  end

  def bibliographic_file?(path)
    File.file?(path) && FILETYPES.key?(File.extname(path).downcase)
  end

  def filetype(path)
    FILETYPES.fetch(File.extname(path).downcase, 'application/octet-stream')
  end
end
