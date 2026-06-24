# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

require 'date'

# @!group Data extraction

# Form to retrieve information from a document
# in stage extract information
get '/review/:sr_id/extract_information/cd/:cd_id' do |sr_id,cd_id|
  halt_unless_auth('review_view')
  @sr=SystematicReview[sr_id]

  raise Buhos::NoReviewIdError, sr_id if !@sr
  @modal_files=get_modal_files


  @cd=CanonicalDocument[cd_id]
  @user=User[session['user_id']]
  return 404 if @sr.nil? or @cd.nil?
  @stage=Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION.to_s
  cds_id=@sr.cd_id_by_stage(@stage)

  if !cds_id.include?(cd_id.to_i)
    add_message(t(:Canonical_documento_not_assigned_to_this_systematic_review), :error)
    redirect back
  end
  adu=AnalysisUserDecision.new(sr_id, @user[:id], @stage)
  if !adu.allocated_to_cd_id(cd_id)
    add_message(t(:Canonical_documento_not_assigned_to_this_user), :error)
    redirect back
  end

  @files_id=FileCd.
    join(:file_srs, :file_id=>:file_id).
    where(:canonical_document_id=>cd_id, :systematic_review_id=>@sr[:id]).
    where(Sequel.lit("file_cds.not_consider = ? OR file_cds.not_consider IS NULL", 0)).
    exclude(Sequel[:file_cds][:file_id]=>FileExtractionInformation.where(:systematic_review_id=>@sr[:id]).select(:file_id)).
    select_map(Sequel[:file_cds][:file_id])
  @files=IFile.where(:id=>@files_id).as_hash
  @global_files=AnalysisSystematicReview.new(@sr).global_files_by_cd[@cd[:id]] || []

  @current_file_id = params['file'] || @files.keys[0]

  @current_file = @files[@current_file_id]
  @file_extraction_informations=FileExtractionInformation.
    where(:systematic_review_id=>@sr[:id], :canonical_document_id=>@cd[:id], :user_id=>@user[:id]).
    order(:id)
  @file_extraction_information_files=IFile.where(:id=>@file_extraction_informations.map(:file_id)).as_hash


  @ars=AnalysisSystematicReview.new(@sr)

  @ads=AnalysisUserDecision.new(sr_id, @user[:id], @stage)

  @decisions=@ads.decisions

  @form_creator=FormBuilder.new(@sr, @cd, @user)
  @incoming_citations=CanonicalDocument.where(:id=>@ars.incoming_citations(@stage,cd_id)).order(:year,:author)
  @outgoing_citations=CanonicalDocument.where(:id=>@ars.outgoing_citations(@stage,cd_id)).order(:year,:author)

  haml "systematic_reviews/cd_extract_information".to_sym, escape_html: false
end

# Upload a file used as guideline for the information extraction form.
post '/review/:sr_id/extract_information/cd/:cd_id/file_extraction_information/add' do |sr_id,cd_id|
  halt_unless_auth('review_analyze')

  sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !sr

  cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !cd

  user=User[session['user_id']]
  stage=Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION.to_s
  adu=AnalysisUserDecision.new(sr_id, user[:id], stage)
  if !sr.cd_id_by_stage(stage).include?(cd_id.to_i) || !adu.allocated_to_cd_id(cd_id)
    add_message(t(:Canonical_documento_not_assigned_to_this_user), :error)
    redirect back
  end

  files_param=params['file_extraction_information']
  files=files_param.is_a?(Array) ? files_param : [files_param]
  files=files.find_all {|file| file && file[:tempfile]}

  if files.any?
    files.each do |file|
      file_proc=FileProcessor.new(file, dir_files)
      file_proc.add_to_sr(sr)
      FileExtractionInformation.insert(:file_id=>file_proc.file_id,
                                       :systematic_review_id=>sr[:id],
                                       :canonical_document_id=>cd[:id],
                                       :user_id=>user[:id],
                                       :created_at=>DateTime.now)
    end
    add_message("Archivo de pauta subido", :success)
  else
    add_message(I18n::t(:Files_not_uploaded), :error)
  end
  redirect url("/review/#{sr[:id]}/extract_information/cd/#{cd[:id]}")
end

# Remove a guideline file from the information extraction form.
post '/review/:sr_id/extract_information/cd/:cd_id/file_extraction_information/:id/delete' do |sr_id,cd_id,id|
  halt_unless_auth('review_analyze')

  file_extraction_information=FileExtractionInformation[:id=>id,
                                                        :systematic_review_id=>sr_id,
                                                        :canonical_document_id=>cd_id,
                                                        :user_id=>session['user_id']]
  return 404 if file_extraction_information.nil?
  file_extraction_information.delete
  add_message("Archivo de pauta eliminado", :success)
  redirect url("/review/#{sr_id}/extract_information/cd/#{cd_id}")
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


get '/review/:sr_id/:action/cd/:cd_id/by_similarity' do |sr_id,action, cd_id|
  halt_unless_auth('review_analyze')

  return 500, I18n::t(:No_valid_action) unless ['extract_information', 'quality_assessment'].include? action
  @sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  @user=User[session['user_id']]

  extraction_stage=Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION
  @ads=AnalysisUserDecision.new(sr_id, @user[:id], extraction_stage)
  undecided=@ads.decision_by_cd.find_all {|v| v[1]==Decision::NO_DECISION}.map {|v|v[0]}

  if undecided.length==0
    add_message(t(:No_undecided_documents_left), :success)
    redirect url("/review/#{@sr[:id]}/#{extraction_stage}")
  else
    sim_an=Buhos::SimilarAnalysisSr.new(@sr)
    sim_an.process
    sato=sim_an.similarity_all_to_one(cd_id).find_all {|v| undecided.include? v[:id]}.sort_by{|a| a[:similarity]}.last
    redirect url("/review/#{@sr[:id]}/#{action}/cd/#{sato[:id]}")
  end
  ""

end


# @!endgroup
