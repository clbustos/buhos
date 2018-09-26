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
  class CriteriaProcessor
    attr_reader :error
    def initialize(sr)
      @sr=sr
      @error=false
    end
    def update_criteria(inclusion, exclusion)
      # Criteria already defined
      inclusion||=[]
      exclusion||=[]
      inclusion=inclusion.map {|v| v.to_s.chomp}.delete_if {|v| v==""}
      exclusion=exclusion.map {|v| v.to_s.chomp}.delete_if {|v| v==""}

      process_array(inclusion, 'inclusion')
      process_array(exclusion, 'exclusion')

    end

    def process_array(param_array, type)
      previous_ids=SrCriterion.where(:criteria_type=>type.to_s, :systematic_review_id=>@sr.id).select_map(:criterion_id)
      new_ids=[]
      param_array.each do |text|
        crit=Criterion.get_criterion(text.chomp)
        new_ids.push(crit[:id])
        SrCriterion.sr_criterion_add(@sr,crit, type)
      end

      to_delete=previous_ids-new_ids
      to_delete.each do |criterion_id|
        SrCriterion.sr_criterion_remove(@sr, Criterion[criterion_id])
      end
    end
  end
end