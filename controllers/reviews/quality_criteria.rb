# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Analysis form


# List of personalized fields
get '/review/:rs_id/quality_assesment_criteria' do |rs_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  @sr_quality_criteria=SrQualityCriterion.join(:quality_criteria, id: :quality_criterion_id).where(systematic_review_id:rs_id)

  @xselect=get_xeditable_select(Scale.to_hash, "/review/#{rs_id}/edit_quality_criterion/scale_id", 'select-criteria')
  haml  "systematic_reviews/quality_criteria".to_sym
end

# Add a new field

post '/review/:rs_id/new_quality_criterion' do |rs_id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  text=params['text'].chomp
  if text==""
    add_message("quality_asessment.criterion_cant_be_empty", :error)
  else
    quality_criterion=QualityCriterion.get_criterion(text)
    scale=Scale[params['scale_id']]
    raise Buhos::NoScaleIdError, params['scale_id'] unless scale

    add_result(Buhos::QualityCriteriaProcessor.add_criterion_to_rs(@review,quality_criterion, scale))
  end
  redirect back
end

# Edit specific attribute of a field
put '/review/:sr_id/edit_quality_criterion/:attr' do |sr_id, attr|
  halt_unless_auth('review_admin')

  review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, rs_id unless review

  return [500, t('quality_assesment.invalid_attribute', field:attr)] unless %w{order text scale_id}.include? attr
  qc_id = params['pk']
  value = params['value']


  qc=QualityCriterion[qc_id]
  raise Buhos::NoQualityCriterionIdError, qc_id unless qc
  srqc=SrQualityCriterion[systematic_review_id:sr_id, quality_criterion_id:qc_id]
  if %w{order scale_id}.include? attr
    srqc.update(attr.to_sym => value)
  elsif attr=='text'
    res=Buhos::QualityCriteriaProcessor.change_criterion_name(review,qc,value)
    return[500, res.message] unless res.success?
  end
  return 200
end



# Delete a quality criteria
post '/review/:sr_id/quality_criterion/:qc_id/delete' do  |sr_id, qc_id|
  halt_unless_auth('review_admin')
  review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, rs_id unless review
  quality_criterion=QualityCriterion[qc_id]
  raise Buhos::NoQualityCriterionIdError, qc_id unless quality_criterion

  SrQualityCriterion[systematic_review_id:sr_id, quality_criterion_id:qc_id].delete
  add_message(I18n::t('quality_assesment.criterion_unassigned_from_rs', criterion:quality_criterion[:text], review:review[:name]))
  redirect back
end

# @!endgroup