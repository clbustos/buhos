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
    def self.merge(pks)
      new(pks).merge
    end

    def initialize(pks)
      @pks = pks.map { |v| v.to_i }
      @pk_id = @pks[0]
      @pk_otros = @pks[1...@pks.length]
    end

    def merge
      resultado = true
      $db.transaction(:rollback => :reraise) do
        update_canonical_document_fields
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
      related_tables.each do |table|
        pk = $db.schema(table).find_all { |v| v[1][:primary_key] }.map { |v| v[0] }

        cache = []
        $db[table].select(*pk).where(:canonical_document_id => @pks).each do |row|
          fixed_row = row.dup
          fixed_row[:canonical_document_id] = @pk_id
          if cache.include? fixed_row
            $db[table].where(row).delete
          else
            cache.push(fixed_row)
          end
        end

        $db[table].where(:canonical_document_id => @pks).update(:canonical_document_id => @pk_id)
      end
    end

    def related_tables
      table_list = [:allocation_cds, :bib_references, :cd_criteria, :decisions, :file_cds,
                    :resolutions, :tag_in_cds, :records, :canonical_document_authors]

      SystematicReview.all.each do |sr|
        table_list.push(sr.analysis_cd_tn.to_sym) if $db.table_exists?(sr.analysis_cd_tn)
      end

      table_list
    end

    def merge_between_document_tags
      $db[:tag_bw_cds].where(:cd_start => @pks).update(:cd_start => @pk_id)
      $db[:tag_bw_cds].where(:cd_end => @pks).update(:cd_end => @pk_id)
    end
  end
end
