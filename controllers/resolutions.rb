# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group stages administration

# Set resolution of a specific canonical document on a stage
post '/resolution/review/:id/canonical_document/:cd_id/stage/:stage/resolution' do |rev_id, cd_id, stage|
  halt_unless_auth('review_admin')
  resolution=params['resolution']
  user_id=params['user_id']

  if resolution=='delete'
    return 404 unless Resolution.delete_for_document(systematic_review_id:rev_id, canonical_document_id:cd_id, stage:stage)
  else
    return 500 unless [Resolution::RESOLUTION_ACCEPT, Resolution::RESOLUTION_REJECT].include? resolution
    Resolution.set_for_document(
      systematic_review_id:rev_id,
      canonical_document_id:cd_id,
      stage:stage,
      resolution:resolution,
      user_id:user_id,
      commentary:"Resuelto en forma especifica en #{DateTime.now.to_s}"
    )
  end

  review=SystematicReview[rev_id]
  ars=AnalysisSystematicReview.new(review)

  rpc=ars.resolution_by_cd(stage)
  rcompc=ars.resolution_commentary_by_cd(stage)

  partial(:buttons_resolution, :locals=>{:rpc=>rpc, :rcompc=>rcompc, :cd_id=>cd_id.to_i, :stage=>stage, :user_id=>user_id, :review=>review})
end

put '/resolution/review/:id/canonical_document/:cd_id/stage/:stage/user/:user_id/resolution_commentary' do |rev_id, cd_id, stage, user_id|
  halt_unless_auth('review_admin')
  Resolution.update_commentary_for_document(
    systematic_review_id:rev_id,
    canonical_document_id:cd_id,
    stage:stage,
    user_id:user_id,
    commentary:params['value'].chomp
  )
  return 200
end

# @!endgroup
