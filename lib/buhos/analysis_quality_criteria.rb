# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
  class AnalysisQualityCriteria
    attr_reader :sr
    attr_reader :criteria
    attr_reader :cd_ids
    attr_reader :scale_items
    def initialize(sr)
      @sr=sr
      @criteria=SrQualityCriterion.join(:quality_criteria, id: :quality_criterion_id).where(systematic_review_id:@sr.id).order(:order)
      set_canonical_documents
      @criteria_id=@criteria.map(:quality_criterion_id)
      @users_id=@sr.group_users.map(&:id)
      @user_n=@users_id.length
      @cd_criteria=CdQualityCriterion.where(systematic_review_id:@sr.id, quality_criterion_id: @criteria_id, canonical_document_id:@cd_ids).order(:user_id, :canonical_document_id, :quality_criterion_id)

      @scale_items=ScalesItem.join(:scales, id: :scale_id).select_all(:scales_items).where(scale_id: @criteria.map {|v| v[:scale_id]}.uniq ).to_hash_groups(:scale_id)
    end

    def set_canonical_documents
      @cd_ids=@sr.cd_id_by_stage(:report)
    end
    private :set_canonical_documents
    def proportion_by_cd
      crit_perc=lambda {@criteria.inject({}) { |ac,criterion|
        ac[criterion[:id]]=@scale_items[criterion[:scale_id]].inject({}) do |ac2,v2|

          ac2[v2[:value]]=0
          ac2
        end
        ac
      }}

      percents=@cd_ids.inject({}) do |ac,cd_id|
        ac[cd_id]=crit_perc.call
        ac
      end

      @cd_criteria.each do |row|

        percents[row[:canonical_document_id]][row[:quality_criterion_id]][row[:value]]+= 1.to_f/@user_n
      end
      percents

    end
  end
end