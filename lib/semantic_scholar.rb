# Copyright (c) 2022, Claudio Bustos Navarrete
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


require 'json'
require_relative 'doi_helpers'
require_relative 'error_codes'

#

module SemanticScholar


  class Remote
    include DOIHelpers
    attr_accessor :ss
    attr_accessor :error
    BASE_URL="https://api.semanticscholar.org/graph/v1/paper/"

    def initialize
      @ss=nil
      @error=nil
    end

    def retrieve_json(url)
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
      if res.code!="200"
        raise Buhos::SemanticScholarError, "Can't retrieve information for  #{uri}. CODE: #{res.code}, Body:#{res.body}"
      else
        res.body
      end
    end

    def json_by_id(id, type)
      if type==:doi
        id=doi_without_http(id)
      end
      if type!=:s2
        id_ss="#{type.to_s.upcase}:#{id}"
      else
        id_ss="#{id}"
      end
      fields="paperId,title,year,abstract,url,venue,fieldsOfStudy,authors"
      url="#{BASE_URL}#{id_ss}?fields=#{fields}"
      retrieve_json(url)
    end

    # @param id Id to retrieve. By default, doi
    # @param type type of identifier. By default, doi, but could it be ARXIV, PMID
    def record_by_id(id, type=:doi, fields="paperId,title,year,abstract,url")

      if type==:doi
        id=doi_without_http(id)
      end
      if type!=:s2
        id_ss="#{type.to_s.upcase}:#{id}"
      else
        id_ss="#{id}"
      end

      url="#{BASE_URL}#{id_ss}?fields=#{fields}"
      process(url)
    end
  end

end
