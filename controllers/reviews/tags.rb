# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Tags related to systematic reviews


# Interface for stage screening titles and abstract
get '/review/:id/tags/user/:user_id' do |sr_id, user_id|
  halt_unless_auth('review_analyze')
  @review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user
  @a_tags=Buhos::AnalysisTags.new
  @a_tags.systematic_review_id sr_id
  @a_tags.user_id  user_id

  @sim_an=Buhos::SimilarAnalysisSr.new(@review)

  @sim_an.process

  haml "systematic_reviews/tags_analysis".to_sym
end


# @!endgroup