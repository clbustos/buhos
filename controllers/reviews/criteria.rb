# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Inclusion and exclusion criteria



post '/review/criteria/cd' do


  cd = CanonicalDocument[params['cd_id']]
  sr = SystematicReview[params['sr_id']]
  user = User[params['user_id']]
  criterion=Criterion[params['criterion_id']]
  presence = params['presence']

  raise Buhos::NoReviewIdError, params['sr_id'] if !sr
  raise Buhos::NoCdIdError , params['cd_id'] if !cd
  raise Buhos::NoUserIdError, params['user_id'] if !user
  raise Buhos::NoCriterionIdError, params['criterion_id'] if !criterion
  if scoped_researcher?
    halt_unless_auth('review_analyze')
    halt 403 unless is_session_user(user.id)
    halt 404 unless sr.cd_all_id_table.where(cd_id: cd.id).first &&
      $db[:sr_criteria].where(systematic_review_id: sr.id, criterion_id: criterion.id).first
  end

  raise I18n::t("criteria.not_valid_presence_type", type:presence) unless CdCriterion.valid_presence? presence


  h_crit={criterion_id:criterion[:id], canonical_document_id: cd[:id], user_id:user[:id], systematic_review_id: sr[:id]}
  cd_criteria=CdCriterion[h_crit]
  if !cd_criteria
    CdCriterion.insert(h_crit.merge({presence:presence}))
  else
    cd_criteria.update(presence:presence)
  end

  cd_criteria_list=CdCriterion.where(systematic_review_id:sr[:id], canonical_document_id:cd[:id], user_id:user[:id]).to_hash(:criterion_id)

  partial(:criteria_cd, locals:{review:sr, cd:cd, user_id:user[:id], cd_criteria:cd_criteria_list, open:true})
end

# @!endgroup
