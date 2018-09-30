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

#
module Buhos
  class AnalysisIncExcCriteria
    attr_reader :sr
    def initialize(sr)
      @sr=sr
      @criteria=SrCriterion.join(:criteria, id: :criterion_id).where(systematic_review_id:@sr.id).order(:criteria_type, :criterion_id)
      set_canonical_documents
      @users_id=@sr.group_users.map(&:id)
      @cd_criteria=CdCriterion.where(systematic_review_id:@sr.id)
    end

    def set_canonical_documents
      cd_ids_with_dec=Decision.where(systematic_review_id:@sr.id).select(:canonical_document_id).group(:canonical_document_id).map(&:canonical_document_id).uniq
      cd_included=@sr.cd_all_id
      @cd_ids=cd_ids_with_dec & cd_included
    end

    def percent_by_cd
      crit_perc=@criteria.inject({}) do |ac,criterion|
        ac[criterion[:id]]=0
        ac
      end
      percents=@cd_ids.inject({}) do |ac,cd_id|
        ac[cd_id]=crit_perc.dup
        ac
      end
      @cd_criteria.each do |row|
        $log.info(row)
        next unless @cd_ids.include? row[:canonical_document_id]
        percents[row[:canonical_document_id]][row[:criterion_id]]+=1
      end
      percents

    end
  end
end






