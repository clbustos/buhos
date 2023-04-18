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
module Buhos
  # Analysis of decision by cd
  class AnalysisCdDecisions
    def initialize(sr, stage)
      @sr    = sr
      @stage = stage
      @all_decisions=all_decisions
      @user_names=@sr.group_users.inject({}) {|ac,v| ac[v[:id]]=v[:name];ac }
      #@all_allocations=all_allocations
    end
    def all_allocations
      cds=@sr.cd_id_by_stage(@stage)
      allocations=AllocationCd.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :stage=>@stage.to_s).select_hash_groups(:canonical_document_id, :user_id)
      allocations
    end
    def all_decisions
      cds=@sr.cd_id_by_stage(@stage)
      decisions=Decision.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :user_id=>@sr.group_users.map {|u| u[:id]}, :stage=>@stage.to_s).to_hash_groups(:canonical_document_id)
      decisions
    end

    def to_text(cd_id)
      if @all_decisions.nil? or @all_decisions[cd_id].nil?
        return ""
      end
      res_raw=@all_decisions[cd_id].inject({}) do |ac,v|
        dec=v[:decision]
        ac[dec]||=[]
        text=v[:commentary].nil? ? @user_names[v[:user_id]] : "#{@user_names[v[:user_id]]}  (#{v[:commentary]})"
        ac[dec].push(text)
        ac
      end
      out_html=res_raw.map do |dec,v|
        dec_name=I18n::t(Decision.get_name_decision(dec))
        author_html=v.map {|v| "#{v}"}
        "**#{dec_name}** : #{author_html.join('; ')} | "
      end
      "#{out_html.join("\n")}"
    end

    def to_html(cd_id)
      if @all_decisions.nil? or @all_decisions[cd_id].nil?
        return ""
      end
      res_raw=@all_decisions[cd_id].inject({}) do |ac,v|
        dec=v[:decision]
        ac[dec]||=[]
        text=v[:commentary].nil? ? @user_names[v[:user_id]] : "#{@user_names[v[:user_id]]}  (#{v[:commentary]})"
        ac[dec].push(text)
        ac
      end
      out_html=res_raw.map do |dec,v|
        dec_name=I18n::t(Decision.get_name_decision(dec))
        author_html=v.map {|v| "<span class='decision-author'>#{v}</span>"}
        "<li><span class='decision-name'>#{dec_name}</span>: #{author_html.join('; ')}</li>"
      end
      "<ul>\n#{out_html.join("\n")}\n</ul>"
    end

    #@param cd_id canonical document id
    #@param dec decision taken
    def text_decision_cd(cd_id, dec)

      res=@all_decisions[cd_id].find_all {|v| v[:decision]==dec}.map {|v|
        v[:commentary].nil? ? "#{@user_names[v[:user_id]]}" : "#{@user_names[v[:user_id]]} : #{v[:commentary]}"
      }


      res.join(" | \n")
    end
  end
end