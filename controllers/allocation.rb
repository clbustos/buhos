# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Allocation of canonical documents to users

# Provide instruction for a user on a given allocation
put '/allocation/user/:user_id/review/:rs_id/cd/:cd_id/stage/:stage_id/edit_instruction' do |user_id, rs_id, cd_id,stage|
  halt_unless_auth('review_admin')

  pk = params['pk']
  value = params['value']
  AllocationCd.where(:systematic_review_id=>rs_id, :canonical_document_id=>cd_id, :user_id=>user_id, :stage=>stage).update(:instruction=>value.chomp)
  return true
end


# @!endgroup