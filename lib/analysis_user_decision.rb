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

# Information about decisions taken by an user, on a systematic review of a specific stage

class AnalysisUserDecision
  # Raw dataset of Decision
  attr_reader :decisions
  # Decision for each assignment
  attr_reader :decision_by_cd
  # Number of document for each type of decision
  attr_reader :total_decisions
  # Raw dataset of AllocationCd
  attr_reader :assignations
  def initialize(rs_id,user_id,stage)
    @rs_id=rs_id
    @user_id=user_id
    @stage=stage.to_s
    @assignations=nil?
    procesar_cd_ids
    process_basic_indicators
    #procesar_numero_citas
  end
  def systematic_review
    @rs||=SystematicReview[@rs_id]
  end
  def canonical_documents
    CanonicalDocument.where(:id=>@cd_ids)
  end
  def have_allocations?
    !@assignations.empty?
  end
  def allocated_to_cd_id(cd_id)
    @cd_ids.include? cd_id.to_i
  end
  def decision_cd_id(cd_id)
    @decision_by_cd[cd_id]
  end
  # Define @cd_ids. Si no se han asignado, los toma todos
  # Si existen asignaciones, sólo se consideran estas
  def procesar_cd_ids
    cd_stage=systematic_review.cd_id_by_stage(@stage)
    @assignations=AllocationCd.where(:systematic_review_id=>@rs_id, :user_id=>@user_id, :canonical_document_id=>cd_stage, :stage=>@stage)
    if @assignations.empty?
      @cd_ids=[]
    else
      @cd_ids=@assignations.select_map(:canonical_document_id)
    end
  end
  def process_basic_indicators
    if @cd_ids.empty?
      @decisions=[]
      @decision_by_cd={}
      @total_decisions={}
    else
      @decisions=Decision.where(:user_id => @user_id, :systematic_review_id => @rs_id,
                                 :stage => @stage, :canonical_document_id=>@cd_ids).as_hash(:canonical_document_id)


      @decision_by_cd=@cd_ids.inject({}) {|ac, cd_id|
        dec_id=@decisions[cd_id]

        dec_dec=dec_id  ? dec_id[:decision] : Decision::NO_DECISION
        dec_dec=Decision::NO_DECISION if dec_dec.nil?
        ac[cd_id]=dec_dec
        ac
      }
      @total_decisions=@cd_ids.inject({}) {|ac,cd_id|
        dec=@decision_by_cd[cd_id]
        dec_i= dec.nil? ? Decision::NO_DECISION : dec
        ac[ dec_i]||=0
        ac[ dec_i]+=1
        ac
      }
    end
  end
end