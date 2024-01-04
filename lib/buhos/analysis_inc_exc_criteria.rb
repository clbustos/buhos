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
  class AnalysisIncExcCriteria
    attr_reader :sr
    attr_reader :criteria
    attr_reader :cd_ids
    def initialize(sr)
      @sr=sr
      @criteria=SrCriterion.join(:criteria, id: :criterion_id).where(systematic_review_id:@sr.id).order(:criteria_type, :criterion_id)
      set_canonical_documents
      @users_id=@sr.group_users.map(&:id)
      @user_n=@users_id.length
      @criteria_id=@criteria.map {|crit| crit[:id]}
      @cd_criteria=CdCriterion.where(systematic_review_id:@sr.id, canonical_document_id:@cd_ids, criterion_id:@criteria_id ).order(:user_id, :canonical_document_id, :criterion_id)
    end

    def set_canonical_documents
      cd_ids_with_dec=Decision.where(systematic_review_id:@sr.id).select(:canonical_document_id).group(:canonical_document_id).map(&:canonical_document_id).uniq
      cd_included=@sr.cd_all_id
      @cd_ids=cd_ids_with_dec & cd_included
    end
    private :set_canonical_documents
    def proportion_by_cd

      crit_perc=lambda {@criteria.inject({}) { |ac,criterion|
        ac[criterion[:id]]=CdCriterion::PRESENCE_VALID.inject({}) {|ac2,presence| ac2[presence]=0; ac2}
        ac
      }}
      percents=@cd_ids.inject({}) do |ac,cd_id|
        ac[cd_id]=crit_perc.call
        ac
      end
      #$log.info(percents)
      @cd_criteria.each do |row|

        next unless @cd_ids.include? row[:canonical_document_id] and @criteria_id.include? row[:criterion_id]

        percents[row[:canonical_document_id]][row[:criterion_id]][row[:presence]]+= 1.to_f/@user_n
      end
      percents

    end
  end
end






