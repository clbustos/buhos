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

require_relative 'stages'

#
module Buhos
  class InconsistenciesAnalysis
    include StagesMixin
    attr_reader :systematic_review
    def initialize(rs)
      @systematic_review=rs
    end
    # Check the canonical documents that have resolutions,
    # but no canonical_documents that support them
    def resolutions_without_cd_support

      stages=[Buhos::Stages::STAGE_SCREENING_TITLE_ABSTRACT,
             Buhos::Stages::STAGE_REVIEW_FULL_TEXT,
              Buhos::Stages::STAGE_SCREENING_REFERENCES]

      result=stages.inject({}) {|ac,stage|
        cds=@systematic_review.cd_id_by_stage(stage)
        cd_res=Resolution.where(systematic_review_id:@systematic_review[:id],
                                stage:stage.to_s).map(:canonical_document_id).uniq
        ac[stage]=cd_res-cds
        ac
      }
      result
    end

    def resolve_inconsistencies_resolutions(stage)
      result=Result.new
      rws=resolutions_without_cd_support
      cd_list=rws[stage.to_sym]
      n=cd_list.length
      $db.transaction do
        Resolution.where(systematic_review_id:@systematic_review[:id],
                         stage:stage.to_s,
                         canonical_document_id:cd_list).delete
        result.success(I18n::t('removed_n_canonical_documents',n:n))
        $db.after_rollback {
          result.error(I18n::t('error_deleting_canonical_documents'))
        }
      end

      result
    end

    def decisions_without_cd_support

      stages=[Buhos::Stages::STAGE_SCREENING_TITLE_ABSTRACT,
              Buhos::Stages::STAGE_REVIEW_FULL_TEXT,
              Buhos::Stages::STAGE_SCREENING_REFERENCES]

      result=stages.inject({}) {|ac,stage|
        cds=@systematic_review.cd_id_by_stage(stage)
        cd_res=Decision.where(systematic_review_id:@systematic_review[:id],
                                stage:stage.to_s).map(:canonical_document_id).uniq
        ac[stage]=cd_res-cds
        ac
      }
      #$log.info(result  )
      result
    end


    def resolve_inconsistencies_decisions(stage)
      result=Result.new
      dws=decisions_without_cd_support
      cd_list=dws[stage.to_sym]
      n=cd_list.length
      $db.transaction do
        Decision.where(systematic_review_id:@systematic_review[:id],
                         stage:stage.to_s,
                         canonical_document_id:cd_list).delete
        result.success(I18n::t('removed_n_canonical_documents',n:n))
        $db.after_rollback {
          result.error(I18n::t('error_deleting_canonical_documents'))
        }
      end

      result
    end

  end
end