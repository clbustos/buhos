# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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
  # Stores the
  class EfetchXMLSummaries
    attr_reader :summaries
    def initialize
      @summaries=[]
    end
    include Enumerable
    def [](i)
      @summaries[i]
    end
    def each
      @summaries.each do |e|
        yield e
      end
    end
    # Checks that e is Nokogiri::XML::Document object or nil
    def push(e)
      raise "Not a Nokogiri::Document or nil object" unless e.nil? or e.is_a? Nokogiri::XML::Document
      @summaries.push(e)
    end

  end

  class EfetchResponseError < StandardError

  end
  class Efetch
    BASE_URL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    MAX_SLICE=150
    TOOL="buhos"
    EMAIL="clbustos.2@gmail.com"
    attr_reader :pmid_list
    attr_reader :pmid_xml
    def initialize(pmid_list)
      @pmid_list=pmid_list
      @pmid_xml=EfetchXMLSummaries.new
      @processed=false
    end
    # NCBI request that the users should get 200 or less ids
    # So, we use MAX_SLICE as maximum slice to make requests
    def process
      return true if @processed
      @pmid_list.each_slice(MAX_SLICE) do |slice_pmid|
        process_slice(slice_pmid)

        #while out!=:ok
        #  out=process_slice(slice_pmid)
        #end
      end
      @processed
      #$log.info(@pmid_xml.keys)
    end

    def process_slice(slice_pmid)
      url="#{BASE_URL}?tool=#{TOOL}&email=#{EMAIL}#{PMC.api_key}&db=pubmed&retmode=xml&id=#{slice_pmid.join(',')}"
      #$log.info(url)
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
      #$log.info(res.body)
      begin
        xml_o=Nokogiri::XML(res.body)
      rescue
        xml_o=nil
      end
      #$log.info(res.body)
      if res.code!="200"
        raise EfetchResponseError, "Can't retrieve information for slice #{slice_pmid}. CODE: #{res.code}, Body:#{res.body}"
      else
        if xml_o
          @pmid_xml.push(xml_o)
          :ok
        else
          raise "Problem to get slice #{slice_pmid}"
        end
      end
    end
  end
end