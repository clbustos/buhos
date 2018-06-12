# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group canonical documents assigned to reviews

get "/review/:sr_id/canonical_document/:cd_id" do |sr_id, cd_id|
  halt_unless_auth('review_view')
  @sr_id=sr_id
  @cd_id=cd_id
  @sr=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr
  @cd=CanonicalDocument[@cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd
  haml "systematic_reviews/canonical_document".to_sym
end

get %r{/review/(\d+)/canonical_document/(\d+)/(cites|cited_by|cited_by_rtr)} do
  halt_unless_auth('review_view')
  @sr_id=params[:captures][0]
  @cd_id=params[:captures][1]
  @type=params[:captures][2]
  @sr=SystematicReview[@sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr
  @cd=CanonicalDocument[@cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd
  @rwc= AnalysisSystematicReview.reference_between_canonicals(@sr)
  @cd_to_show=@rwc.send(@type.to_sym, @cd_id)
  haml "systematic_reviews/canonical_document_cites".to_sym
end

# @!endgroup