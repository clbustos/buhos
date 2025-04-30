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

#
module Buhos
  # Class to analysis groups of searches:
  # - Resolutions of each document on every stage
  # - Databases and types of every search
  class AnalysisSearches
    attr_reader :searches
    attr_reader :searches_id
    def initialize(searches)

      @searches=searches
      @searches_id=@searches.map(&:id)
    end
    def sql_in
      "IN (#{searches_id.join(",")})"
    end
    def records
      Record.join(:records_searches, record_id: :id ).where(search_id: @searches_id)
    end
    def canonical_documents_id
      records.map(&:canonical_document_id).uniq
    end
    def records_by_cd
      $db["SELECT canonical_document_id, COUNT(*) as n FROM records_searches rs
INNER JOIN records r ON rs.record_id=r.id WHERE rs.search_id #{sql_in} GROUP BY r.canonical_document_id ORDER BY n desc"]
    end
    def resolutions_by_cd(sr,stage)
      ars=Analysis_SR_Stage.new(sr,stage)
      rbc=ars.resolutions_by_cd
      canonical_documents_id.inject({}) do |ac,v|
        ac[v]=rbc[v]
        ac
      end
    end

    def resolutions_by_cd_summary(sr,stage)
      resolutions_by_cd(sr, stage).inject({}) {|ac,v|
        type=v[1].nil? ? Resolution::PREVIOUS_REJECT : v[1]
        ac[type]||=0
        ac[type]+=1
        ac
      }
    end


    def records_by_cd_summary
      records_by_cd.inject({}) do |ac,v|
        ac[v[:n]]||=0
        ac[v[:n]]+=1
        ac
      end
    end
    def summary_sources_databases
      $db["SELECT  s.source, s.bibliographic_database_id,  COUNT(*) as n FROM records r
    INNER JOIN records_searches rs ON r.id=rs.record_id
    INNER JOIN searches s ON s.id=rs.search_id WHERE s.id #{sql_in}
    GROUP BY  s.source, s.bibliographic_database_id ORDER BY s.source, s.bibliographic_database_id"]
    end
  end
end