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

require 'json'
# Class to store Semantic_Scholar_Paper

class Semantic_Scholar_Paper < Sequel::Model
  # Obtain a tuple, using semantic_scholar_id or doi
  # @param type 'semantic_scholar_id' or 'doi'
  def self.get(type, id)

    if type.to_s=='semantic_scholar_id'
      Semantic_Scholar_Paper[id]
    elsif type.to_s=='doi'
      Semantic_Scholar_Paper.where(:doi => id).first
    else
      raise Buhos::NoSemanticScholarMethodError, ::I18n.t("error.no_semantic_scholar_method", type:type)
    end
  end


  def self.add_from_json(json,doi=nil)
    json_o=JSON.parse(json)
    ss=Semantic_Scholar_Paper[json_o["paperId"]]
    if !ss
      Semantic_Scholar_Paper.insert(:id => json_o["paperId"], :json => json , :doi => doi)
    end

  end

  def self.get_abstract_cd(cd_id)
    result=Result.new
    cd=CanonicalDocument[cd_id]
    doi=cd.doi
    #$log.info("Procesando scopus para CD:#{cd.id}")
    if cd.semantic_scholar_id
      type='semantic_scholar_id'
      id=cd.semantic_scholar_id
    elsif cd.doi
      type='doi'
      id=cd.doi
    else
      result.error(I18n::t("semantic_scholar_paper.cant_obtain_suitable_identificator", cd_title:cd[:title]))
      return result
    end


    sa=Semantic_Scholar_Paper.get(type, id)
    if !sa
      begin
        sr=SemanticScholar::Remote.new
        json=sr.json_by_id(id, type)
      rescue SocketError => e
        json=false
        sr=OpenStruct.new
        sr.error=e.message
      end

      if json
        add_from_json(json, doi)
        json_o=JSON.parse(json)
      else
        result.error(I18n::t("semantic_scholar_paper.cant_obtain_semantic_scholar_error", cd_title:cd[:title], sr_error: sr.error))
        return result
      end
    else
      json_o=JSON.parse(sa[:json])
    end



    if json_o["abstract"].to_s==""
      result.error(I18n::t("semantic_scholar_paper.no_semantic_scholar_abstract",cd_title:cd[:title]))
    elsif cd.abstract.to_s==""
      cd.update(:abstract => json_o["abstract"], :semantic_scholar_id=> json_o["paperId"])
      result.success(I18n::t("semantic_scholar_paper.updated_abstract",cd_title:cd[:title]))
    end

    result
  end
end