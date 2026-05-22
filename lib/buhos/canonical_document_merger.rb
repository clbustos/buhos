# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module Buhos
  class CanonicalDocumentMerger
    CANONICAL_DOCUMENT_FK = :canonical_document_id

    RELATED_TABLE_RULES = {
      allocation_cds: { column: CANONICAL_DOCUMENT_FK },
      bib_references: { column: CANONICAL_DOCUMENT_FK },
      canonical_document_authors: { column: CANONICAL_DOCUMENT_FK },
      cd_criteria: { column: CANONICAL_DOCUMENT_FK },
      cd_quality_criteria: { column: CANONICAL_DOCUMENT_FK },
      favorite_documents: { column: CANONICAL_DOCUMENT_FK },
      file_cds: { column: CANONICAL_DOCUMENT_FK },
      file_extraction_informations: { column: CANONICAL_DOCUMENT_FK },
      records: { column: CANONICAL_DOCUMENT_FK },
      sr_document_reports: {
        column: CANONICAL_DOCUMENT_FK,
        deduplicate_by: [:systematic_review_id, :canonical_document_id, :user_id, :report_type]
      },
      tag_in_cds: { column: CANONICAL_DOCUMENT_FK },
      useless_cd_allocations: { column: CANONICAL_DOCUMENT_FK }
    }.freeze

    BETWEEN_DOCUMENT_RULES = {
      tag_bw_cds: [:cd_start, :cd_end]
    }.freeze

    SPECIAL_MERGE_RULES = {
      decisions: { column: CANONICAL_DOCUMENT_FK },
      resolutions: { column: CANONICAL_DOCUMENT_FK }
    }.freeze

    def self.merge(pks)
      new(pks).merge
    end

    def self.missing_merge_rules
      expected = canonical_document_references
      covered = merge_rule_references

      expected.each_with_object({}) do |(table, columns), missing|
        unknown_columns = columns - Array(covered[table])
        missing[table] = unknown_columns if unknown_columns.any?
      end
    end

    def self.validate_merge_rules!
      missing = missing_merge_rules
      return if missing.empty?

      details = missing.map { |table, columns| "#{table}(#{columns.join(', ')})" }.join(', ')
      raise "Missing canonical document merge rules for: #{details}"
    end

    def initialize(pks)
      @pks = pks.map { |v| v.to_i }
      @pk_id = @pks[0]
      @pk_otros = @pks[1...@pks.length]
    end

    def merge
      resultado = true
      $db.transaction(:rollback => :reraise) do
        self.class.validate_merge_rules!
        update_canonical_document_fields
        merge_decisions
        merge_resolutions
        merge_related_tables
        merge_between_document_tags
        CanonicalDocument.where(:id => @pk_otros).delete

        $db.after_rollback {
          resultado = false
        }
      end
      resultado
    end

    private

    def self.merge_rule_references
      references = {}

      RELATED_TABLE_RULES.each do |table, rule|
        references[table] ||= []
        references[table] << rule[:column]
      end

      SPECIAL_MERGE_RULES.each do |table, rule|
        references[table] ||= []
        references[table] << rule[:column]
      end

      BETWEEN_DOCUMENT_RULES.each do |table, columns|
        references[table] ||= []
        references[table].concat(columns)
      end

      dynamic_analysis_tables.each do |table|
        references[table] ||= []
        references[table] << CANONICAL_DOCUMENT_FK
      end

      references
    end

    def self.canonical_document_references
      real_tables.each_with_object({}) do |table, references|
        columns = canonical_document_reference_columns(table)
        references[table] = columns if columns.any?
      end
    end

    def self.real_tables
      views = $db.respond_to?(:views) ? $db.views : []
      $db.tables - views - [:canonical_documents]
    end

    def self.canonical_document_reference_columns(table)
      foreign_key_columns = foreign_key_reference_columns(table)
      return foreign_key_columns if foreign_key_columns.any?

      schema_columns = $db.schema(table).map { |column| column[0] }
      schema_columns & ([CANONICAL_DOCUMENT_FK] + BETWEEN_DOCUMENT_RULES.values.flatten)
    end

    def self.foreign_key_reference_columns(table)
      $db.foreign_key_list(table).each_with_object([]) do |foreign_key, columns|
        next unless foreign_key[:table].to_sym == :canonical_documents

        columns.concat(Array(foreign_key[:columns]))
      end
    rescue Sequel::Error, NoMethodError
      []
    end

    def self.dynamic_analysis_tables
      SystematicReview.all.each_with_object([]) do |sr, tables|
        table = sr.analysis_cd_tn.to_sym
        tables.push(table) if $db.table_exists?(table)
      end
    end

    def update_canonical_document_fields
      columnas = CanonicalDocument.columns
      columnas.delete(:id)

      cds = CanonicalDocument.where(:id => @pks)
      if cds.count != @pks.count
        raise("Ids to merge were #{@pks.join(',')} and retrieved where #{cds.map { |v| v[:id] }.join(',')}")
      end

      fields = columnas.inject({}) { |ac, v| ac[v] = nil; ac }
      cds.each do |cd|
        columnas.find_all { |col| fields[col].nil? || fields[col] == "" || (col == :year && fields[col] == 0) }.each do |col|
          fields[col] = cd[col]
        end
      end

      CanonicalDocument[@pk_id].update(fields)
    end

    def merge_related_tables
      related_table_rules.each do |table, rule|
        fk = rule[:column]
        deduplicate_by = rule[:deduplicate_by] || primary_key_columns(table)

        cache = []
        $db[table].select(*deduplicate_by).where(fk => @pks).each do |row|
          fixed_row = row.dup
          fixed_row[fk] = @pk_id
          if cache.include? fixed_row
            $db[table].where(row).delete
          else
            cache.push(fixed_row)
          end
        end

        $db[table].where(fk => @pks).update(fk => @pk_id)
      end
    end

    def merge_decisions
      Decision.merge_canonical_documents(@pk_id, @pks)
    end

    def merge_resolutions
      Resolution.merge_canonical_documents(@pk_id, @pks)
    end

    def related_table_rules
      table_rules = self.class::RELATED_TABLE_RULES.dup

      self.class.send(:dynamic_analysis_tables).each do |table|
        table_rules[table] = { column: self.class::CANONICAL_DOCUMENT_FK }
      end

      table_rules
    end

    def primary_key_columns(table)
      $db.schema(table).find_all { |v| v[1][:primary_key] }.map { |v| v[0] }
    end

    def merge_between_document_tags
      self.class::BETWEEN_DOCUMENT_RULES.each do |table, columns|
        columns.each do |column|
          $db[table].where(column => @pks).update(column => @pk_id)
        end
      end
    end
  end
end
