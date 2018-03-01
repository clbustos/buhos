get '/review/:sr_id/extract_information/cd/:cd_id' do |sr_id,cd_id|
  halt_unless_auth('review_view')
  @sr=Revision_Sistematica[sr_id]

  raise Buhos::NoReviewIdError, sr_id if !@sr


  @cd=Canonico_Documento[cd_id]
  @user=Usuario[session['user_id']]
  return 404 if @sr.nil? or @cd.nil?
  @stage='review_full_text'
  cds_id=@sr.cd_id_por_etapa(@stage)

  if !cds_id.include?(cd_id.to_i)
    agregar_mensaje(t(:Canonical_documento_not_assigned_to_this_systematic_review), :error)
    redirect back
  end
  adu=AnalysisUserDecision.new(sr_id, @user[:id], 'review_full_text')
  if !adu.asignado_a_cd_id(cd_id)
    agregar_mensaje(t(:Canonical_documento_not_assigned_to_this_user), :error)
    redirect back
  end
  @files_id=Archivo_Cd.where(:canonico_documento_id=>cd_id, :no_considerar=>false).map(:archivo_id)
  @files=Archivo.where(:id=>@files_id).as_hash

  @current_file_id = params['file'] || @files.keys[0]

  @current_file = @files[@current_file_id]


  @ars=AnalysisSystematicReview.new(@sr)

  @ads=AnalysisUserDecision.new(sr_id, @user[:id], @stage)

  @decisiones=@ads.decisiones

  @form_creator=FormBuilder.new(@sr, @cd, @user)
  @incoming_citations=Canonico_Documento.where(:id=>@ars.incoming_citations(@stage,cd_id)).order(:year,:author)
  @outgoing_citations=Canonico_Documento.where(:id=>@ars.outgoing_citations(@stage,cd_id)).order(:year,:author)

  haml "systematic_reviews/cd_extract_information".to_sym
end


put '/review/:sr_id/extract_information/cd/:cd_id/user/:user_id/update_field' do |sr_id,cd_id,user_id|
  halt_unless_auth('review_analyze')

  @sr=Revision_Sistematica[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=Canonico_Documento[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

  @user=Usuario[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  field = params['pk']
  value = params['value']
  fila=@sr.analisis_cd_user_row(@cd,@user)
  @sr.analisis_cd.where(:id=>fila[:id]).update(field.to_sym=>value.chomp)
  return true
end