# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Screening and analysis of documents

# Retrieve the interface to make decision on a document

get '/decision/review/:review_id/user/:user_id/canonical_document/:cd_id/stage/:stage' do |review_id, user_id, cd_id, stage|
  halt_unless_auth('review_view')
  review=SystematicReview[review_id]
  cd=CanonicalDocument[cd_id]
  ars=AnalysisSystematicReview.new(review)
  usuario=User[user_id]
  decisions=Decision.where(:user_id => user_id, :systematic_review_id => review_id,
                            :stage => stage).as_hash(:canonical_document_id)
  if !review or !cd or !usuario
    return [500, "No existe alguno de los componentes"]
  end
  return partial(:decision, :locals => {review: review, cd: cd, decisions: decisions, ars: ars, user_id: user_id, stage: stage})
end

# Put a commentary for a specific document on analysis

put '/decision/review/:review_id/user/:user_id/canonical_document/:cd_id/stage/:stage/commentary' do |review_id, user_id, cd_id, stage|
  halt_unless_auth('review_analyze')
  pk = params['pk']
  value = params['value']
  $db.transaction(:rollback => :reraise) do
    des=Decision.where(:systematic_review_id => review_id, :user_id => user_id, :canonical_document_id => pk, :stage => stage).first
    if des
      des.update(:commentary => value)
    else
      Decision.insert(:systematic_review_id => review_id,
                      :decision => nil,
                      :user_id => user_id, :canonical_document_id => pk, :stage => stage, :commentary => value.strip)
    end
  end
  return 200
end

# Make a decision on a given document

post '/decision/review/:review_id/user/:user_id/canonical_document/:cd_id/stage/:stage/decision' do |review_id, user_id, cd_id, stage|
  halt_unless_auth('review_analyze')
  #cd_id=params['pk_id']
  decision=params['decision']
  #user_id=params['user_id']
  only_buttons = params['only_buttons'] == "1"

  $db.transaction do
    des=Decision.where(:systematic_review_id => review_id, :user_id => user_id, :canonical_document_id => cd_id, :stage => stage).first
    if des
      des.update(:decision => decision)
    else
      Decision.insert(:systematic_review_id => review_id,
                      :decision => decision,
                      :user_id => user_id, :canonical_document_id => cd_id, :stage => stage)
    end
  end
  review=SystematicReview[review_id]

  cd=CanonicalDocument[cd_id]
  ars=AnalysisSystematicReview.new(review)
  decisions=Decision.where(:user_id => user_id, :systematic_review_id => review_id,
                            :stage => stage).as_hash(:canonical_document_id)


  return partial(:decision, :locals => {review: review, cd: cd, decisions: decisions, ars: ars, user_id: user_id, stage: stage, ajax: true, only_buttons:only_buttons})


end

# @!endgroup