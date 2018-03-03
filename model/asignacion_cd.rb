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

require_relative 'revision_sistematica'
require_relative 'seguridad'
require_relative 'canonico_documento'


class AllocationCd < Sequel::Model
  many_to_one :systematic_review    , :class=>SystematicReview
  many_to_one :user_name            , :class=>User
  many_to_one :canonical_document   , :class=>CanonicalDocument

  def self.update_assignation(rev_id, cds_id, user_id,stage, status=nil)
    current=AllocationCd.where(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage).map(:canonical_document_id)

    to_remove=current-cds_id
    to_add=cds_id-current
    $db.transaction do
      AllocationCd.where(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage, :canonical_document_id=>to_remove).delete
      to_add.each do |cd_id|
        AllocationCd.insert(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage, :canonical_document_id=>cd_id, :status=>status)
      end
    end
    user=User[user_id]
    result=Result.new()
    result.success(I18n::t(:result_assignation_cd_to_user, :added=>to_add.length, :removed=>to_remove.length, :user_name=>user[:name]))
    result
  end


end