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

class Scopus_Abstract < Sequel::Model
  def self.get(type, id)
    if type.to_s=='eid'
      Scopus_Abstract[id]
    elsif type.to_s=='doi'
      Scopus_Abstract.where(:doi => id).first
    else
      raise Buhos::NoScopusMethodError, ::I18n.t("error.no_scopus_method", type:type)
    end
  end

  def self.add_from_xml(xml)
    sa=Scopus_Abstract[xml.eid]
    if !sa
      Scopus_Abstract.insert(:id => xml.eid, :xml => xml.xml.to_s, :doi => xml.doi)
    end

  end

  def self.get_abstract_cd(cd_id)
    result=Result.new
    cd=CanonicalDocument[cd_id]
    #$log.info("Procesando scopus para CD:#{cd.id}")
    if cd.scopus_id
      type='eid'
      id=cd.scopus_id.gsub("eid=", "")
    elsif cd.doi
      type='doi'
      id=cd.doi
    else
      result.error(I18n::t("scopus_abstract.cant_obtain_identificator_suitable_for_scopus", cd_title:cd[:title]))
      return result
    end


    sa=Scopus_Abstract.get(type, id)
    if !sa
      begin
        sr=ScopusRemote.new
        xml=sr.xml_abstract_by_id(id, type)
      rescue SocketError => e
        xml=false
        sr=OpenStruct.new
        sr.error=e.message
      end
      if xml
        add_from_xml(xml)
      else
        result.error(I18n::t("scopus_abstract.cant_obtain_scopus_error", cd_title:cd[:title], sr_error: sr.error))
        return result
      end
    else
      xml=ElsevierApi.process_xml(sa[:xml])
    end




    if xml.abstract.to_s==""
      result.error(I18n::t("scopus_abstract.no_scopus_abstract",cd_title:cd[:title]))
    elsif cd.abstract.to_s==""
      cd.update(:abstract => xml.abstract)
      result.success(I18n::t("scopus_abstract.updated_abstract",cd_title:cd[:title]))
    end

    result
  end
end