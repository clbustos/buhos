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
module PMC
  # Error when Id Converter API doesn't provide a valid response
  class IDConverterApiResponseError < StandardError

  end

  # Get PMID for a list of Doi, using ID Converter API from NCBI
  # https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/
  class DoiToPmidProcessor
    BASE_URL="https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/"
    MAX_SLICE=150
    TOOL="buhos"
    EMAIL="clbustos.2@gmail.com"
    attr_reader :doi_list
    attr_reader :doi_as_pmid
    attr_reader :doi_bad
    def initialize(doi_list)
      @doi_list=doi_list
      @doi_as_pmid={}
      @doi_bad=[]
    end
    # NCBI request that the users should get 200 or less ids
    # So, we use MAX_SLICE as maximum slice to make requests
    def process
      @doi_list.each_slice(MAX_SLICE) do |slice_doi|
        out=process_doi_slice(slice_doi)
        while out!=:ok
          out=process_doi_slice(slice_doi)
        end
      end
    end
    def process_doi_slice(slice_doi)
      slice_doi.delete_if {|v|
        @doi_bad.include? v
      }

      slice_doi_url=slice_doi.map {|v| CGI.escape(v)}.join(",")
      url="#{BASE_URL}?tool=#{TOOL}&email=#{EMAIL}#{PMC.api_key}&idtype=doi&format=json&versions=no&ids=#{slice_doi_url}"
      #$log.info(url)
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
      #$log.info(res.body)
      begin
        json=JSON.parse(res.body)
      rescue
        json=nil
      end

      if res.code!="200"
        message=json ? CGI.unescape(json["message"]) : nil
        if message=~/ID type of '(.+?)' is unknown/ or message=~/ID type 'doi' mismatch for '(.+?)'/
          @doi_bad.push($1)
          return :retry
        else
          raise IDConverterApiResponseError, "Can't retrieve information for slice #{slice_doi_url}. CODE: #{res.code}, Body:#{res.body}"
        end

      else
        if json
          if json["status"]!="ok"
            raise IDConverterApiResponseError, "Error on JSON retrieval #{res.body}"
          else
            json["records"].each {|record|
              @doi_as_pmid[record['doi']]=record["pmid"]
            }
          end
          :ok
        else
          :error
        end

      end
    end
  end
end