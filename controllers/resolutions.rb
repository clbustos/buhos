# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


post '/resolution/review/:id/canonical_document/:cd_id/stage/:stage/resolution' do |rev_id, cd_id, stage|
  halt_unless_auth('review_admin')
  resolution=params['resolution']
  user_id=params['user_id']

  return 500 unless ['yes','no'].include? resolution
  $db.transaction(:rollback=>:reraise) do

    res=Resolution.where(:systematic_review_id=>rev_id, :canonical_document_id=>cd_id, :stage=>stage)
    if res.empty?
      Resolution.insert(:systematic_review_id=>rev_id, :canonical_document_id=>cd_id, :stage=>stage, :resolution=>resolution, :user_id=>user_id, :commentary=>"Resuelto en forma especifica en #{DateTime.now.to_s}")
    else
      res.update(:resolution=>resolution, :user_id=>user_id, :commentary=>"Actualizado en forma especifica en #{DateTime.now.to_s}")
    end
  end

  review=SystematicReview[rev_id]
  ars=AnalysisSystematicReview.new(review)

  rpc=ars.resolution_by_cd (stage)

  partial(:buttons_resolution, :locals=>{:rpc=>rpc, :cd_id=>cd_id.to_i, :stage=>stage, :user_id=>user_id, :review=>review})
end