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

class Pmc_Summary < Sequel::Model
  # Obtain a tuple, using pmid or doi
  # @param type 'pmid' or 'doi'
  def self.get(type, id)

    if type.to_s=='pmid'
      Pmc_Summary[id]
    elsif type.to_s=='doi'
      Pmc_Summary.where(:doi => id).first
    else
      raise Buhos::NoPmcMethodError, ::I18n.t("error.no_pmc_method", type:type)
    end
  end

  # If a
  def self.add_from_bi_response(bir)
    sa=Pmc_Summary[bir.pmid]
    if !sa
      Pmc_Summary.insert(:id => bir.pmid, :xml => bir.xml.to_s, :doi => bir.doi)
    end

  end

# TODO: Implement this.
  def self.get_abstract_for_cd(cd_id)
    raise "Not implemented yet"
    result=Result.new
    cd=CanonicalDocument[cd_id]



    #$log.info("Procesando scopus para CD:#{cd.id}")
    if cd.pmid
      type='pmid'
      id=cd.pmid
    elsif cd.doi
      type='doi'
      id=cd.doi
    else
      result.error(I18n::t("pmc_summary.cant_obtain_identificator_suitable_for_pubmed", cd_title:cd[:title]))
      return result
    end


    ps=Pmc_Summary.get(type, id)

    if !ps
      ps=PmcRemote.new
      exs=ps.exs_by_id(id, type)
      if exs
        add_from_exs(exs)
      else
        result.error(I18n::t("pmc_summary.cant_obtain_pmc_error", cd_title:cd[:title], exs_error: exs.error))
        return result
      end
    else
      bi=BibliographicalImporter::PmcEfetchXml::Reader.parse(exs)
    end



    if xml.abstract.to_s==""
      result.error(I18n::t("pmc_summary.no_pmc_abstract",cd_title:cd[:title]))
    elsif cd.abstract.to_s==""
      cd.update(:abstract => xml.abstract)
      result.success(I18n::t("pmc_summary.updated_abstract",cd_title:cd[:title]))
    end

    result
  end
end