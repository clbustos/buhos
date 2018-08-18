# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Data extraction

# Form to retrieve information from a document
# in stage review full text
get '/review/:sr_id/extract_information/cd/:cd_id' do |sr_id,cd_id|
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

  @form_creator=FormBuilder.new(@sr, @cd, @user)
  @incoming_citations=CanonicalDocument.where(:id=>@ars.incoming_citations(@stage,cd_id)).order(:year,:author)
  @outgoing_citations=CanonicalDocument.where(:id=>@ars.outgoing_citations(@stage,cd_id)).order(:year,:author)

  haml "systematic_reviews/cd_extract_information".to_sym
end

# Update information of a specific personalized field

put '/review/:sr_id/extract_information/cd/:cd_id/user/:user_id/update_field' do |sr_id,cd_id,user_id|
  halt_unless_auth('review_analyze')

  @sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  field = params['pk']
  value = params['value']
  fila=@sr.analysis_cd_user_row(@cd,@user)
  if value.nil?
    value_store=nil
  elsif value.is_a? Array
    value_store=value.join(",")
  else
    value_store=value.chomp
  end

  @sr.analysis_cd.where(:id=>fila[:id]).update(field.to_sym=>value_store)
  return true
end

# @!endgroup