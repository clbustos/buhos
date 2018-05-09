# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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


# Class that query Crossref for a DOI
# and stores the result
class CrossrefDoi < Sequel::Model
  include DOIHelpers
  extend DOIHelpers
  # Given a DOI, query Crossref, store the result
  # and return a raw JSON
  # @param doi [String] a DOI
  # @return [String] raw JSON from Crossref or false if Crossref doesn't have information
  # @raise [ArgumentError] if DOI is nil
  # TODO: Create a independent class to handle relation with external services
  def self.procesar_doi(doi)
    require 'serrano'
    raise ArgumentError, 'DOI is nil' if doi.nil?
    co=CrossrefDoi[doi_without_http(doi)]
    if !co or co[:json].nil?
      begin
        resultado=Serrano.works(ids: CGI.escape(doi))
      rescue Serrano::NotFound=>e
        return false
      rescue URI::InvalidURIError
        #$log.info("Malformed URI: #{doi}")
        return false
      end
      if co
        co.update(:json=>resultado.to_json)
      else
        CrossrefDoi.insert(:doi=>doi_without_http(doi),:json=>resultado.to_json)
        co=CrossrefDoi[doi_without_http(doi)]
      end
    end
    co[:json]
  end

  # Returns Reference_Integrator::JSON::Reader
  # for a DOI.
  # @param doi
  # @return BibliographicalImporter::JSON::Reader
  def self.reference_integrator_json(doi)
    co=self.procesar_doi(doi)
    if(co)
      BibliographicalImporter::JSON::Reader.parse(co)[0]
    else
      false
    end
  end
end


# Error when Crossref doesn't provide a valid response
# for a text query
# @see CrossrefQuery.generate_query_from_text
class BadCrossrefResponseError < StandardError

end

# Class that query Crossref for a given text
# and stores the result

class CrossrefQuery < Sequel::Model
  # Takes a text and returns a processed JSON
  # @param t [String] a text that represents a document
  # @return a processed json
  # @raise [BadCrossrefResponseError] if Crossref raises an error
  def self.generate_query_from_text(t)
    require 'digest'
    digest=Digest::SHA256.hexdigest t
    cq=CrossrefQuery[digest]

    if !cq
      url="https://search.crossref.org/dois?q=#{CGI.escape(t)}"
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
      #$log.info(res)
      if res.code!="200"
        raise BadCrossrefResponseError, "El text #{t} no entrego una respuesta adecuada. Fue #{res.code}, #{res.body}"
      end
      json_raw = res.body
      CrossrefQuery.insert(:id=>digest.force_encoding(Encoding::UTF_8),:query=>t.force_encoding(Encoding::UTF_8),:json=>json_raw.force_encoding(Encoding::UTF_8))
    else
      json_raw=cq[:json]
    end
    JSON.parse(json_raw)
  end

end