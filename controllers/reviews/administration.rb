##### ADMINISTRATION #####

get '/review/:id/administration_stages' do |id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  haml %s{systematic_reviews/administration_stages}

end


get '/review/:id/administration/:stage' do |id,stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]

  raise Buhos::NoReviewIdError, id if !@review


  @stage=stage
  @ars=AnalysisSystematicReview.new(@review)
  @cd_without_assignation=@ars.cd_without_allocations(stage)

  @cds_id=@review.cd_id_by_stage(stage)
  @cds=CanonicalDocument.where(:id=>@cds_id)
  @files_by_cd=@ars.files_by_cd
  ## Aquí calcularé cuantos si y no hay por categoría
  res_stage=@ars.resolution_by_cd(stage)
  begin
    @categorizador=CategorizerSr.new(@review) unless stage==:search
    @aprobacion_categorias=@categorizador.categorias_cd_id.inject({}) {|ac,v|
      cd_validos=res_stage.keys & (v[1])
      n=cd_validos.length
      if n==0
        ac[v[0]] = {n:0, p:nil}
      else
        ac[v[0]] = {n:n, p: cd_validos.find_all {|vv|  res_stage[vv]=='yes' }.length /   n.to_f}
      end
      ac
    }
  rescue LoadError
    @categorizador=nil
  end
  #  $log.info(p_aprobaciones_categoria)
  @name_stage=get_stage_name(@stage)

  @user_id=session['user_id']
  @modal_files=get_modal_files

  if %w{screening_title_abstract screening_references review_full_text}.include? stage
    haml "systematic_reviews/administration_reviews".to_sym
  else
    haml "systematic_reviews/administration_#{stage}".to_sym
  end
end


get '/review/:id/stage/:stage/pattern/:patron/resolution/:resolution' do |id,stage,patron_s,resolution|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  patron=@ars.pattern_from_s(patron_s)
  cds=@ars.cd_from_pattern(stage, patron)

  $log.info(cds)

  $db.transaction(:rollback=>:reraise) do
    cds.each do |cd_id|
      res=Resolution.where(:systematic_review_id=>id, :canonical_document_id=>cd_id, :stage=>stage)

      if res.empty?
        Resolution.insert(:systematic_review_id=>id, :canonical_document_id=>cd_id, :stage=>stage, :resolution=>resolution, :user_id=>session['user_id'], :commentary=>"Resuelto en forma masiva en #{DateTime.now.to_s}")
      else
        res.update(:resolution=>resolution, :user_id=>session['user_id'], :commentary=>"Actualizado en forma masiva en #{DateTime.now.to_s}")

      end
    end
  end
  add_message(I18n::t("resolution_for_n_documents", resolution:resolution, n:cds.length))
  redirect back
end




get '/review/:rev_id/stage/:stage/generar_references_crossref' do |rev_id,stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, id if !@review

  result=Result.new
  dois_agregados=0
  cd_i=Resolution.where(:systematic_review_id=>rev_id, :resolution=>"yes", :stage=>stage.to_s).map {|v|v [:canonical_document_id]}
  cd_i.each do |cd_id|
    @cd=CanonicalDocument[cd_id]

    # first, we process all records pertinent with this canonical document.
    records=Record.where(:canonical_document_id=>cd_id)
    rcp=RecordCrossrefProcessor.new(records,$db)
    result.add_result(rcp.result)
    if @cd.crossref_integrator
      begin
        # Agregar dois a references
        @cd.references_performed.where(:canonical_document_id=>nil).each do |ref|
          # primero agregamos doi si podemos
          # Si tiene doi, tratamos de
          rp=ReferenceProcessor.new(ref)
          if ref.doi.nil?
            dois_agregados+=1 if rp.process_doi
          end

          if !ref.doi.nil?
            result.add_result(ref.add_doi(ref[:doi]))
          end
        end
      rescue Exception=>e
        result.error(e.message)
      end
    else
      result.error(I18n::t("error.error_on_add_crossref_for_cd", cd_title:@cd[:title]))
    end
  end
  result.info(I18n::t(:Search_add_doi_references, :count=>dois_agregados))

  add_result(result)
  redirect back
end



get '/review/:rev_id/administration/:stage/cd_assignations' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  @cds_id=@review.cd_id_by_stage(stage)
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage
  @cds=CanonicalDocument.where(:id=>@cds_id).order(:author)
  @type="all"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end


get '/review/:rev_id/administration/:stage/cd_without_allocations' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)

  @stage=stage
  @cds=@ars.cd_without_allocations(stage).order(:author)
  @type="without_assignation"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end




get '/review/:rev_id/stage/:stage/add_assign_user/:user_id/:type' do |rev_id, stage, user_id,type|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  if type=='all'
    @cds_id=@review.cd_id_by_stage(stage)
  elsif type=='without_assignation'
    ars=AnalysisSystematicReview.new(@review)
    @cds_id_previous=ars.cd_id_assigned_by_user(stage,user_id)
    @cds_id_add=ars.cd_without_allocations(stage).map(:id)
    @cds_id=(@cds_id_previous+@cds_id_add).uniq
  end
  add_result(AllocationCd.update_assignation(rev_id, @cds_id, user_id,stage, 'massive_assigment'))
  redirect back
end


get '/review/:rev_id/stage/:stage/rem_assign_user/:user_id/:type' do |rev_id, stage, user_id, type|
  halt_unless_auth('review_admin')
  # Type doesn't have meaning here
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  add_result(AllocationCd.update_assignation(rev_id, [], user_id,stage))
  redirect back
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_manual' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  haml("systematic_reviews/complete_abstract_manual".to_sym)
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_scopus' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  result=Result.new
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  add_message(I18n::t(:Processing_n_canonical_documents, count:@cd_wo_abstract.count))
  @cd_wo_abstract.each do |cd|
    result.add_result(Scopus_Abstract.obtener_abstract_cd(cd[:id]))
  end
  add_result(result)
  redirect back
end