# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

# Based on an array of records, attach crossref information for each
class RecordCrossrefProcessor
  attr_reader :result
  def initialize(records,db)
    @records=records
    @db=db
    @result=Result.new()
    process_records
  end
  def process_records
    correct=true
    @records.each do |record|
      @db.transaction() do
        begin
          # A very fast comprobation, comparing canonical document and record
          if record.doi.to_s=="" and record.canonical_document.doi!=""
            record.update(:doi=>record.canonical_document.doi)
          else
            @result.add_result(record.add_doi_automatic)
          end
          if record.doi
            result.add_result(record.references_automatic_crossref)
          end
        rescue BadCrossrefResponseError=>e
          result.error(I18n::t("error.problem_record_stop_sync", record_id: record[:id], e_message: e.message))
          raise Sequel::Rollback
        end
        @db.after_rollback {
          correct=false
        }
      end
      break unless correct
    end
  end

end