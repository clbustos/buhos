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

class Criterion < Sequel::Model
  def self.get_criterion(name)
    criterion=Criterion.where(:text=>name).first
    if criterion.nil?
      criterion_id=Criterion.insert(:text=>name)
      criterion=Criterion[criterion_id]
    end
    criterion
  end
end

class SrCriterion < Sequel::Model
  INCLUSION='inclusion'
  EXCLUSION='exclusion'
  TYPES=[INCLUSION, EXCLUSION]
  def self.get_name_type(x)
    "Criteria_#{x}"
  end
  def self.sr_criterion_add(sr,criterion, type)
    type=type.to_s
    raise("Not valid type:#{type}") unless type==INCLUSION or type==EXCLUSION
    unless SrCriterion[systematic_review_id:sr.id, criterion_id:criterion.id]
      SrCriterion.insert(systematic_review_id:sr.id, criterion_id:criterion.id, criteria_type:type)
    end
  end

  def self.sr_criterion_remove(sr,criterion)
    SrCriterion.where(systematic_review_id:sr.id, criterion_id:criterion.id).delete
  end
end


class CdCriterion < Sequel::Model
   PRESENT_YES='present'
   PRESENT_NO='absent'
   PRESENT_CANT_SAY='cant_say'
   PRESENCE_VALID=[PRESENT_YES, PRESENT_NO, PRESENT_CANT_SAY]
   NAMES={  PRESENT_YES       =>"criteria.present",
            PRESENT_NO        =>"criteria.absent",
            PRESENT_CANT_SAY  =>"criteria.cant_say"
   }
   PRESENT_LIST=[PRESENT_YES, PRESENT_NO, PRESENT_CANT_SAY]
   def self.get_name_present(x)
     x.nil? ? "criteria.no_data" : NAMES[x]
   end
  def self.valid_presence?(x)
    PRESENCE_VALID.include? x.to_s
  end
end