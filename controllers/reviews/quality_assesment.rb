# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Quality assesment

# Form to assess quality of a document
# in stage review full text
get '/review/:sr_id/quality_assessment/cd/:cd_id' do |sr_id,cd_id|
  halt_unless_auth('review_view')
  @sr=SystematicReview[sr_id]

  raise Buhos::NoReviewIdError, sr_id if !@sr
  @modal_files=get_modal_files


  @cd=CanonicalDocument[cd_id]
  @user=User[session['user_id']]
  return 404 if @sr.nil? or @cd.nil?
  @stage='review_full_text'
  cds_id=@sr.cd_id_by_stage(@stage)

  if !cds_id.include?(cd_id.to_i)
    add_message(t(:Canonical_documento_not_assigned_to_this_systematic_review), :error)
    redirect back
  end
  adu=AnalysisUserDecision.new(sr_id, @user[:id], 'review_full_text')
  if !adu.allocated_to_cd_id(cd_id)
    add_message(t(:Canonical_documento_not_assigned_to_this_user), :error)
    redirect back
  end

  @files_id=FileCd.where(:canonical_document_id=>cd_id, :not_consider=>false).map(:file_id)
  @files=IFile.where(:id=>@files_id).as_hash

  @current_file_id = params['file'] || @files.keys[0]

  @current_file = @files[@current_file_id]


  @ars=AnalysisSystematicReview.new(@sr)

  @ads=AnalysisUserDecision.new(sr_id, @user[:id], @stage)

  @decisions=@ads.decisions



  @sr_quality_criteria=SrQualityCriterion.join(:quality_criteria, id: :quality_criterion_id).where(systematic_review_id:sr_id)

  @scales_types=@sr_quality_criteria.map {|v| v[:scale_id]}.uniq

  @xselect_a=@scales_types.inject({}) {|ac,v|
    ac[v]=get_xeditable_select(Scale[v].items_hash, "/review/#{sr_id}/quality_assessment/cd/#{@cd[:id]}/user/#{@user[:id]}/evaluation", "scale-#{v}")
    ac
  }

  @url_commentary= "/review/#{sr_id}/quality_assessment/cd/#{@cd[:id]}/user/#{@user[:id]}/commentary"


  @cd_qc=CdQualityCriterion.where(systematic_review_id:sr_id, user_id:@user[:id], canonical_document_id:@cd[:id]).to_hash(:quality_criterion_id)
  $log.info(@cd_qc)
  haml "systematic_reviews/quality_assessment".to_sym, escape_html: false
end


# Update information of a specific quality criterion

put '/review/:sr_id/quality_assessment/cd/:cd_id/user/:user_id/:action' do |sr_id,cd_id,user_id, action|
  halt_unless_auth('review_analyze')

  @sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  qc_id= params['pk']
  value = params['value']

  criteria={systematic_review_id:sr_id, user_id:user_id, canonical_document_id:cd_id, quality_criterion_id:qc_id}

  cd_qc=CdQualityCriterion[criteria]
  scale_id=SrQualityCriterion[systematic_review_id:sr_id, quality_criterion_id:qc_id][:scale_id]
  field=case action
        when 'evaluation' then :value
        when 'commentary' then :commentary
        else
          raise t(:Action_not_defined)
        end
  if cd_qc
    cd_qc.update(field=>value)
  else
    return [500, I18n::t("quality_assesment.cant_comment_before_assessment")] if field==:commentary
    CdQualityCriterion.insert(criteria.merge({scale_id:scale_id, field=>value}))
  end

  return true
end




# @!endgroup