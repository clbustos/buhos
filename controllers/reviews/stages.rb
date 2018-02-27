get '/review/:id/screening_title_abstract' do |id|

  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]


  @pager=get_pager
  @pager.orden||="year__asc"


  @criterios_orden={:title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)


  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/review/#{id}/screening_title_abstract"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'screening_title_abstract')

  @cds_pre=@ads.canonicos_documentos
  @cds_total=@cds_pre.count

  @decisiones=@ads.decisiones
  if @pager.busqueda.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.busqueda==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.ajustar_query(@cds_pre)


  haml %s{systematic_reviews/screening_title_abstract}

end


get '/review/:id/screening_references' do |id|


  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]


  @pager=get_pager()
  @pager.orden||="n_referencias_rtr__desc"


  @criterios_orden={:n_referencias_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)


  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/review/#{id}/screening_references"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'screening_references')

  @cds_pre=@ads.canonicos_documentos.join_table(:inner, @revision.cuenta_referencias_rtr_tn.to_sym, cd_destino: :id)


  @decisiones=@ads.decisiones
  @cds_total=@cds_pre.count

  if @pager.busqueda.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.busqueda==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.ajustar_query(@cds_pre)


  haml %s{systematic_reviews/screening_references}
end


get '/review/:id/review_full_text' do |id|

  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision


  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]


  @pager=get_pager()
  @pager.orden||="year__asc"


  @criterios_orden={:n_referencias_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)

  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/review/#{id}/review_full_text"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'review_full_text')

  @cds_pre=@ads.canonicos_documentos.join_table(:left, @revision.cuenta_referencias_rtr_tn.to_sym, cd_destino: :id)

  @asignaciones=@ads.asignaciones.to_hash(:canonico_documento_id)

  @decisiones=@ads.decisiones
  @cds_total=@cds_pre.count

  if @pager.busqueda.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.busqueda==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end




  @pager.max_page=(@cds_pre.count/@pager.cpp.to_f).ceil

  @cds=@pager.ajustar_query(@cds_pre)


  haml %s{systematic_reviews/review_full_text}
end


##### ADMINISTRATION #####

get '/review/:id/administration_stages' do |id|
  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision
  @ars=AnalisisRevisionSistematica.new(@revision)
  haml %s{systematic_reviews/administration_stages}

end

get '/review/:id/administration/:etapa' do |id,etapa|
  @revision=Revision_Sistematica[id]

  raise Buhos::NoReviewIdError, id if !@revision


  @etapa=etapa
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_without_assignation=@ars.cd_without_assignations(etapa)

  @cds_id=@revision.cd_id_por_etapa(etapa)
  @cds=Canonico_Documento.where(:id=>@cds_id)
  @archivos_por_cd=$db["SELECT a.*,cds.canonico_documento_id FROM archivos a INNER JOIN archivos_cds cds ON a.id=cds.archivo_id INNER JOIN archivos_rs ars ON a.id=ars.archivo_id WHERE revision_sistematica_id=? AND (cds.no_considerar = ? OR cds.no_considerar IS NULL)", @revision.id , 0].to_hash_groups(:canonico_documento_id)
  ## Aquí calcularé cuantos si y no hay por categoría
  res_etapa=@ars.resolucion_por_cd(etapa)
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
  @modal_archivos=get_modalarchivos

  if %w{screening_title_abstract screening_references review_full_text}.include? etapa
    haml "systematic_reviews/administration_reviews".to_sym
  else
    haml "systematic_reviews/administration_#{etapa}".to_sym
  end
end


get '/review/:id/stage/:etapa/pattern/:patron/resolution/:resolucion' do |id,etapa,patron_s,resolucion|
  @revision=Revision_Sistematica[id]
  raise Buhos::NoReviewIdError, id if !@revision

  @ars=AnalisisRevisionSistematica.new(@revision)
  patron=@ars.patron_desde_s(patron_s)
  cds=@ars.cd_desde_patron(etapa,patron)
  $db.transaction(:rollback=>:reraise) do
    cds.each do |cd_id|
      res=Resolucion.where(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa)
      if res.empty?
        Resolucion.insert(:revision_sistematica_id=>id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolucion, :usuario_id=>session['user_id'], :comentario=>"Resuelto en forma masiva en #{DateTime.now.to_s}")
      else
        res.update(:resolucion=>resolucion, :usuario_id=>session['user_id'], :comentario=>"Actualizado en forma masiva en #{DateTime.now.to_s}")

      end
    end
  end
  agregar_mensaje("Resolución #{resolucion} para #{cds.length} documentos")
  redirect back
end




get '/review/:rev_id/stage/:stage/generar_referencias_crossref' do |rev_id,stage|
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
          rp.check_doi
          if !ref.doi.nil?
            result.add_result(ref.agregar_doi(ref[:doi]))
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
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision

  @cds_id=@revision.cd_id_por_etapa(stage)
  @ars=AnalisisRevisionSistematica.new(@revision)
  @stage=stage
  @cds=Canonico_Documento.where(:id=>@cds_id).order(:author)
  @type="all"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end


get '/review/:rev_id/administration/:stage/cd_without_assignations' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalisisRevisionSistematica.new(@revision)

  @stage=stage
  @cds=@ars.cd_without_assignations(stage).order(:author)
  @type="without_assignation"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end




get '/review/:rev_id/stage/:stage/add_assign_user/:user_id/:type' do |rev_id, stage, user_id,type|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  if type=='all'
    @cds_id=@revision.cd_id_por_etapa(stage)
  elsif type=='without_assignation'
    ars=AnalisisRevisionSistematica.new(@revision)
    @cds_id_previous=ars.cd_id_assigned_by_user(stage,user_id)
    @cds_id_add=ars.cd_without_assignations(stage).map(:id)
    @cds_id=(@cds_id_previous+@cds_id_add).uniq
  end
  add_result(Asignacion_Cd.update_assignation(rev_id, @cds_id, user_id,stage, 'massive_assigment'))
  redirect back
end


get '/review/:rev_id/stage/:stage/rem_assign_user/:user_id/:type' do |rev_id, stage, user_id, type|
  # Type doesn't have meaning here
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  add_result(Asignacion_Cd.update_assignation(rev_id, [], user_id,stage))
  redirect back
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_manual' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalisisRevisionSistematica.new(@revision)
  @stage=stage
  @cd_sin_abstract=@ars.cd_without_abstract(stage)
  haml("systematic_reviews/complete_abstract_manual".to_sym)
end


get '/review/:rev_id/stage/:stage/complete_empty_abstract_scopus' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  @ars=AnalisisRevisionSistematica.new(@revision)
  result=Result.new
  @cd_sin_abstract=@ars.cd_without_abstract(stage)
  agregar_mensaje(I18n::t(:Processing_n_canonical_documents, count:@cd_sin_abstract.count))
  @cd_sin_abstract.each do |cd|
    result.add_result(Scopus_Abstract.obtener_abstract_cd(cd[:id]))
  end
  add_result(result)
  redirect back
end


get '/review/:rev_id/stage/:stage/generate_graphml' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{rev_id}_stage_#{stage}.graphml"

  content_type 'application/graphml+xml'
  graphml=GraphML_Builder.new(@revision, stage)
  graphml.generate_graphml
end

get '/review/:rev_id/stage/:stage/generate_bibtex' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  canonicos_id=@revision.cd_id_por_etapa(stage)
  @canonicos_resueltos=Canonico_Documento.where(:id=>canonicos_id).order(:author,:year)

  bib=ReferenceIntegrator::BibTex::Writer.generate(@canonicos_resueltos)
  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_#{stage}.bib"
  content_type 'text/x-bibtex'
  bib.to_s

end


get '/review/:rev_id/stage/:stage/generate_doi_list' do |rev_id, stage|
  @revision=Revision_Sistematica[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@revision
  canonicos_id=@revision.cd_id_por_etapa(stage)
  @canonicos_resueltos=Canonico_Documento.where(:id=>canonicos_id).order(:author,:year).exclude(:doi=>nil)
  dois=@canonicos_resueltos.map {|v| v.doi}.join("\n")

#  headers["Content-Disposition"] = "attachment;filename=systematic_review_#{rev_id}_#{stage}.bib"
  content_type 'text/plain'
  dois

end
