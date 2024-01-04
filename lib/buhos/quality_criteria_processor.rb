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
  class QualityCriteriaProcessor
    # Assign a Quality Criterion to a Systematic Review
    # @return Scale
    def self.add_criterion_to_rs(review,quality_criterion, scale, order=nil)

      if order.nil?
        max_order=SrQualityCriterion.where(systematic_review_id:review[:id] ).max(:order)
        order= max_order.nil?  ? 1 : max_order+1
      end
      res=Result.new
      previous_sr_qc=SrQualityCriterion.where(systematic_review_id:review[:id], quality_criterion_id:quality_criterion[:id])
      if previous_sr_qc.empty?

        SrQualityCriterion.insert(systematic_review_id:review[:id], quality_criterion_id:quality_criterion[:id], scale_id:scale[:id], order:order)
        res.success(I18n::t('quality_assesment.quality_criterion_assigned_to_rs',criterion:quality_criterion[:text], review:review[:name]))
      else
        res.error(I18n::t("quality_assesment.quality_criteria_already_defined", criterion:quality_criterion[:text]))
      end
      res
    end

    # Try to change the name of the criterion. Only works if no other systematic review had it
    def self.change_criterion_name(review,quality_criterion,new_text)
      # Look if other review uses the criterion
      new_text=new_text.chomp.lstrip
      qc_id_old=quality_criterion[:id]
      sr_id=review[:id]
      raise ArgumentError, I18n::t('quality_assesment.criterion_cant_be_empty') unless new_text!=""

      other_reviews=SrQualityCriterion.where(quality_criterion_id: qc_id_old).exclude(systematic_review_id: sr_id)

      old_text=quality_criterion[:text]
      current_sr_qc=SrQualityCriterion[quality_criterion_id:qc_id_old, systematic_review_id: sr_id]
      res=Result.new


      if old_text==new_text
        res.error(I18n::t('quality_assesment.same_criterion'))
      elsif !CdQualityCriterion.where(systematic_review_id:sr_id, quality_criterion_id: qc_id_old).empty?
        res.error(I18n::t("quality_assesment.quality_already_used_delete_for_change", criterion:old_text))
      else
        if other_reviews.empty? and !QualityCriterion[:text=>new_text] # we just can change the name directly on criterion
          quality_criterion.update(text:new_text)
          res.success(I18n::t('quality_assesment.change_text_criterion_to', old_text:old_text, new_text:new_text))
        else # we have to create a new criterion, and delete the old one. But, if previous responses are available
          res.add_result(change_sr_criterion_name(current_sr_qc, new_text))
          # we just stop the process and ask to delete and add manually
        end
      end

      res
    end


    def self.change_sr_criterion_name(sr_qc, new_text )
      res=Result.new
      sr_id=sr_qc[:systematic_review_id]

      res_add=add_criterion_to_rs(SystematicReview[sr_id],
                                    QualityCriterion.get_criterion(new_text),
                                    Scale[sr_qc[:scale_id]],
                                    sr_qc.order)
      if res_add.success?
        old_text=sr_qc[:text]
        sr_qc.delete
        res.success(I18n::t('quality_assesment.change_text_criterion_to', old_text:old_text, new_text:new_text))
      else
        res.add_result(res_add)
      end
      res
    end



  end
end