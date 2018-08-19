# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Inclusion and exclusion criteria


post '/review/:rs_id/criteria/:action' do |rs_id,action|
  halt_unless_auth('review_edit')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  $db.transaction do
    case action
      when "add"
        criterion=Criterion.get_criterion(params['text'].chomp)
        SrCriterion.sr_criterion_add(@review,criterion, params['cr_type'])
      when "remove"
        criterion=Criterion[params['cr_id']]
        SrCriterion.sr_criterion_remove(@review,criterion)
      else
      raise "Unknown action:#{action}"
    end

  end
  partial("systematic_reviews/criteria", :locals=>{sr:@review, ajax:true, type:params['cr_type']})
end



# @!endgroup