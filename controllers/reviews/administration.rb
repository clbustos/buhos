##### ADMINISTRATION #####

get '/review/:id/administration_stages' do |id|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision
  @ars=AnalysisSystematicReview.new(@revision)
  haml %s{systematic_reviews/administration_stages}

end

get '/review/:id/administration/:etapa' do |id,etapa|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[id]

  raise Buhos::NoReviewIdError, id if !@revision


  @etapa=etapa
  @ars=AnalysisSystematicReview.new(@revision)
  @cd_without_assignation=@ars.cd_without_allocations(etapa)

  @cds_id=@revision.cd_id_por_etapa(etapa)
  @cds=Canonico_Documento.where(:id=>@cds_id)
  @archivos_por_cd=$db["SELECT a.*,cds.canonico_documento_id FROM archivos a INNER JOIN archivos_cds cds ON a.id=cds.archivo_id INNER JOIN archivos_rs ars ON a.id=ars.archivo_id WHERE revision_sistematica_id=? AND (cds.no_considerar = ? OR cds.no_considerar IS NULL)", @revision.id , 0].to_hash_groups(:canonico_documento_id)
  ## Aquí calcularé cuantos si y no hay por categoría
  res_etapa=@ars.resolution_by_cd(etapa)
  begin
    @categorizador=CategorizerSr.new(@revision) unless etapa==:search
    @aprobacion_categorias=@categorizador.categorias_cd_id.inject({}) {|ac,v|
      cd_validos=res_etapa.keys & (v[1])
      n=cd_validos.length
      if n==0
        ac[v[0]] = {n:0, p:nil}
      else
        ac[v[0]] = {n:n, p: cd_validos.find_all {|vv|  res_etapa[vv]=='yes' }.length /   n.to_f}
      end
      ac
    }
  rescue LoadError
    @categorizador=nil
  end
  #  $log.info(p_aprobaciones_categoria)
  @nombre_etapa=Revision_Sistematica.get_nombre_etapa(@etapa)

  @usuario_id=session['user_id']
  @modal_archivos=get_modal_files

  if %w{screening_title_abstract screening_references review_full_text}.include? etapa
    haml "systematic_reviews/administration_reviews".to_sym
  else
    haml "systematic_reviews/administration_#{etapa}".to_sym
  end
end


get '/review/:id/stage/:etapa/pattern/:patron/resolution/:resolution' do |id,etapa,patron_s,resolution|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision

  @ars=AnalysisSystematicReview.new(@revision)
  patron=@ars.pattern_from_s(patron_s)
  cds=@ars.cd_from_pattern(etapa, patron)

  $log.info(cds)

  $db.transaction(:rollback=>:reraise) do
    cds.each do |cd_id|
      res=Resolucion.where(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa)

      if res.empty?
        Resolucion.insert(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolution, :usuario_id=>session['user_id'], :comentario=>"Resuelto en forma masiva en #{DateTime.now.to_s}")
      else
        res.update(:resolucion=>resolution, :usuario_id=>session['user_id'], :comentario=>"Actualizado en forma masiva en #{DateTime.now.to_s}")

      end
    end
  end
  add_message(I18n::t("resolution_for_n_documents", resolution:resolution, n:cds.length))
  redirect back
end




get '/review/:rev_id/stage/:stage/generar_referencias_crossref' do |rev_id,stage|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, id if !@revision

  result=Result.new
  dois_agregados=0
  cd_i=Resolucion.where(:revision_sistematica_id=>rev_id, :resolucion=>"yes", :etapa=>stage.to_s).map {|v|v [:canonico_documento_id]}
  cd_i.each do |cd_id|
    @cd=Canonico_Documento[cd_id]

    # first, we process all records pertinent with this canonical document.
    records=Registro.where(:canonico_documento_id=>cd_id)
    rcp=RecordCrossrefProcessor.new(records,$db)
    result.add_result(rcp.result)
    if @cd.crossref_integrator
      begin
        # Agregar dois a referencias
        @cd.referencias_realizadas.where(:canonico_documento_id=>nil).each do |ref|
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
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision

  @cds_id=@revision.cd_id_por_etapa(stage)
  @ars=AnalysisSystematicReview.new(@revision)
  @stage=stage
  @cds=Canonico_Documento.where(:id=>@cds_id).order(:author)
  @type="all"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end


get '/review/:rev_id/administration/:stage/cd_without_allocations' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalysisSystematicReview.new(@revision)

  @stage=stage
  @cds=@ars.cd_without_allocations(stage).order(:author)
  @type="without_assignation"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end




get '/review/:rev_id/stage/:stage/add_assign_user/:user_id/:type' do |rev_id, stage, user_id,type|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  if type=='all'
    @cds_id=@revision.cd_id_por_etapa(stage)
  elsif type=='without_assignation'
    ars=AnalysisSystematicReview.new(@revision)
    @cds_id_previous=ars.cd_id_assigned_by_user(stage,user_id)
    @cds_id_add=ars.cd_without_allocations(stage).map(:id)
    @cds_id=(@cds_id_previous+@cds_id_add).uniq
  end
  add_result(Asignacion_Cd.update_assignation(rev_id, @cds_id, user_id,stage, 'massive_assigment'))
  redirect back
end


get '/review/:rev_id/stage/:stage/rem_assign_user/:user_id/:type' do |rev_id, stage, user_id, type|
  halt_unless_auth('review_admin')
  # Type doesn't have meaning here
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  add_result(Asignacion_Cd.update_assignation(rev_id, [], user_id,stage))
  redirect back
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_manual' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalysisSystematicReview.new(@revision)
  @stage=stage
  @cd_sin_abstract=@ars.cd_without_abstract(stage)
  haml("systematic_reviews/complete_abstract_manual".to_sym)
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_scopus' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalysisSystematicReview.new(@revision)
  result=Result.new
  @cd_sin_abstract=@ars.cd_without_abstract(stage)
  add_message(I18n::t(:Processing_n_canonical_documents, count:@cd_sin_abstract.count))
  @cd_sin_abstract.each do |cd|
    result.add_result(Scopus_Abstract.obtener_abstract_cd(cd[:id]))
  end
  add_result(result)
  redirect back
end