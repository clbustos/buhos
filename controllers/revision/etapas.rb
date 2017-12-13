get '/revision/:id/revision_titulo_resumen' do |id|

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]
  @pagina=params['pagina'].to_i
  @pagina=1 if @pagina<1
  @cpp=params['cpp']
  @cpp||=20
  @busqueda=params['busqueda']

  # $log.info(params)
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/revision/#{id}/revision_titulo_resumen"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'revision_titulo_resumen')

  @cds_pre=@ads.canonicos_documentos

  @decisiones=@ads.decisiones
  if @busqueda

    cd_ids=@ads.decision_por_cd.find_all {|v|
      @busqueda==v[1]
    }.map {|v| v[0]}
    ##$log.info(cd_ids)
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end


  @cds_total=@cds_pre.count

  @max_page=(@cds_total/@cpp.to_f).ceil
  @pagina=1 if @pagina>@max_page


  @cds=@cds_pre.offset((@pagina-1)*@cpp).limit(@cpp).order(:author, :year)


  haml %s{revisiones_sistematicas/revision_titulo_resumen}


end


get '/revision/:id/revision_referencias' do |id|

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]


  @pager=get_pager()
  @pager.orden||="n_referencias_rtr__desc"


  @criterios_orden={:n_referencias_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)

  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/revision/#{id}/revision_referencias"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'revision_referencias')

  @cds_pre=@ads.canonicos_documentos.join_table(:inner, @revision.cuenta_referencias_rtr_tn.to_sym, cd_destino: :id)


  @decisiones=@ads.decisiones
  if @pager.busqueda.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.busqueda==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end



  @cds_total=@cds_pre.count

  @pager.max_page=(@cds_total/@pager.cpp.to_f).ceil

  @cds=@pager.ajustar_query(@cds_pre)


  haml %s{revisiones_sistematicas/revision_referencias}
end


get '/revision/:id/revision_texto_completo' do |id|

  @usuario=Usuario[session['user_id']]
  @usuario_id=@usuario[:id]


  @pager=get_pager()
  @pager.orden||="year__asc"


  @criterios_orden={:n_referencias_rtr=>I18n.t(:RTA_references), :title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  # $log.info(params)

  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos


  @url="/revision/#{id}/revision_texto_completo"

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'revision_texto_completo')

  @cds_pre=@ads.canonicos_documentos.join_table(:left, @revision.cuenta_referencias_rtr_tn.to_sym, cd_destino: :id)

  @asignaciones=@ads.asignaciones.to_hash(:canonico_documento_id)

  @decisiones=@ads.decisiones
  if @pager.busqueda.to_s!=""
    cd_ids=@ads.decision_por_cd.find_all {|v|
      @pager.busqueda==v[1]
    }.map {|v| v[0]}
    @cds_pre=@cds_pre.where(:id => cd_ids)
  end



  @cds_total=@cds_pre.count

  @pager.max_page=(@cds_total/@pager.cpp.to_f).ceil

  @cds=@pager.ajustar_query(@cds_pre)


  haml %s{revisiones_sistematicas/revision_texto_completo}
end



get '/revision/:id/administracion_etapas' do |id|
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  haml %s{revisiones_sistematicas/administracion_etapas}

end

get '/revision/:id/administracion/:etapa' do |id,etapa|
  @revision=Revision_Sistematica[id]
  @etapa=etapa
  @ars=AnalisisRevisionSistematica.new(@revision)
  @categorizador=Categorizador_RS.new(@revision)

  @cds_id=@revision.cd_id_por_etapa(@revision.etapa)
  @cds=Canonico_Documento.where(:id=>@cds_id)
  @archivos_por_cd=$db["SELECT a.*,cds.canonico_documento_id FROM archivos a INNER JOIN archivos_cds cds ON a.id=cds.archivo_id INNER JOIN archivos_rs ars ON a.id=ars.archivo_id WHERE revision_sistematica_id=? AND (cds.no_considerar = ? OR cds.no_considerar IS NULL)", @revision.id , 0].to_hash_groups(:canonico_documento_id)
  ## Aquí calcularé cuantos si y no hay por categoría
  res_etapa=@ars.resolucion_por_cd(etapa)
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
#  $log.info(p_aprobaciones_categoria)
  @nombre_etapa=Revision_Sistematica.get_nombre_etapa(@etapa)

  @usuario_id=session['user_id']
  @modal_archivos=get_modalarchivos

  if %w{revision_titulo_resumen revision_referencias}.include? etapa
    haml "revisiones_sistematicas/administracion_revisiones".to_sym
  else
    haml "revisiones_sistematicas/administracion_#{etapa}".to_sym
  end
end


get '/revision/:id/etapa/:etapa/patron/:patron/resolucion/:resolucion' do |id,etapa,patron_s,resolucion|
  @revision=Revision_Sistematica[id]
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

post '/resolucion/revision/:id/canonico_documento/:cd_id/etapa/:etapa/resolucion' do |rev_id, cd_id, etapa|

  resolucion=params['resolucion']
  user_id=params['user_id']


  $db.transaction(:rollback=>:reraise) do

    res=Resolucion.where(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa)
    if res.empty?
      Resolucion.insert(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa, :resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Resuelto en forma especifica en #{DateTime.now.to_s}")
    else
      res.update(:resolucion=>resolucion, :usuario_id=>user_id, :comentario=>"Actualizado en forma especifica en #{DateTime.now.to_s}")
    end
  end

  revision=Revision_Sistematica[rev_id]
  ars=AnalisisRevisionSistematica.new(revision)

  res=Resolucion.where(:revision_sistematica_id=>rev_id, :canonico_documento_id=>cd_id, :etapa=>etapa)


  rpc=ars.resolucion_por_cd (etapa)

  partial(:botones_resolucion, :locals=>{:rpc=>rpc, :cd_id=>cd_id.to_i, :etapa=>etapa, :usuario_id=>user_id, :revision=>revision})
end



get '/revision/:rev_id/etapa/revision_titulo_resumen/generar_referencias_crossref' do |rev_id|
  @revision=Revision_Sistematica[rev_id]
  result=Result.new
  cd_i=Resolucion.where(:revision_sistematica_id=>rev_id, :resolucion=>"yes", :etapa=>"revision_titulo_resumen").map {|v|v [:canonico_documento_id]}
  cd_i.each do |cd_id|
    @cd=Canonico_Documento[cd_id]
    if @cd.crossref_integrator
      begin
        @cd.referencias_realizadas.exclude(:doi=>nil).where(:canonico_documento_id=>nil).each do |ref|
          result.add_result(ref.agregar_doi(ref[:doi]))
        end
      rescue Exception=>e
        result.error(e.message)
      end
      agregar_resultado(result)
    else
      result.error("Error al agregar Crossref para #{cd_id}")
    end
  end
  agregar_resultado(result)
  redirect back
end
