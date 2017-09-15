

get '/revisiones' do 
  error(403) unless permiso('ver_revisiones')
  @usuario=Usuario[session['user_id']]
  @inactivas=params['inactivas']
  @revisiones=Revision_Sistematica.get_revisiones_por_usuario(@usuario.id)
  @revisiones=@revisiones.where(:activa => 1) unless @inactivas
  haml :revisiones
end

get "/revision/:id" do |id|
  @revision=Revision_Sistematica[id]
  @nombres_trs=@revision.get_nombres_trs
  ##$log.info(@nombres_trs)
  haml %s{revisiones_sistematicas/ver}
end

get "/revision/:id/edicion" do |id|
  @revision=Revision_Sistematica[id]

  haml %s{revisiones_sistematicas/edicion}
end


get "/revision/:id" do |id|
  @revision=Revision_Sistematica[id]
  @nombres_trs=@revision.get_nombres_trs
  ##$log.info(@nombres_trs)
  haml %s{revisiones_sistematicas/ver}
end


get '/revision/nuevo' do
  @revision=Revision_Sistematica.new
  haml %s{revisiones_sistematicas/edicion}
end


post '/revision/actualizar' do
  id=params['revision_id']
  otros_params=params
  otros_params.delete("revision_id")
  otros_params.delete("captures")
  #No nulos
  ##$log.info(otros_params)
  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
#  aa=Revision_Sistematica.new
  
  if(id=="")
    revision=Revision_Sistematica.create(
      :nombre=>otros_params[:nombre],
      :grupo_id=>otros_params[:grupo_id],
      :trs_foco_id=>otros_params[:trs_foco_id],
      :trs_objetivo_id=>otros_params[:trs_objetivo_id],
      :trs_perspectiva_id=>otros_params[:trs_perspectiva_id],
      :trs_cobertura_id=>otros_params[:trs_cobertura_id],
      :trs_organizacion_id=>otros_params[:trs_organizacion_id],
      :trs_destinatario_id=>otros_params[:trs_destinario_id]
      
      )
  else
    revision=Revision_Sistematica[id]
    revision.update(otros_params)
  end

  redirect url("/revisiones")
end


get '/revision/:id/busquedas' do |id|
  error(403) unless permiso('ver_revisiones')
  @revision=Revision_Sistematica[id]
  @busquedas=@revision.busquedas
  haml %s{revisiones_sistematicas/busquedas}
end
get '/revision/:id/busqueda/nuevo' do |id|
  error(403) unless permiso('crear_busqueda_revision')
  @revision=Revision_Sistematica[id]
  @busqueda=Busqueda.new()
  haml %s{revisiones_sistematicas/busqueda_edicion}
end

post '/revision/busqueda/actualizar' do
  error(403) unless permiso('crear_busqueda_revision')

  id=params['busqueda_id']
  otros_params=params
  otros_params.delete("busqueda_id")
  otros_params.delete("captures")

  archivo=otros_params.delete("archivo")
  #No nulos

  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
  #  aa=Revision_Sistematica.new

  if id==""
    busqueda=Busqueda.create(
        :revision_sistematica_id=>otros_params[:revision_sistematica_id],
        :base_bibliografica_id=>otros_params[:base_bibliografica_id],
        :fecha=>otros_params[:fecha],
        :criterio_busqueda=>otros_params[:criterio_busqueda],
        :descripcion=>otros_params[:descripcion]
    )
  else
    busqueda=Busqueda[id]
    busqueda.update(otros_params)
  end

  if(archivo)
    fp=File.open(archivo[:tempfile],"rb")
    busqueda.update(:archivo_cuerpo=>fp.read, :archivo_tipo=>archivo[:type],:archivo_nombre=>archivo[:filename])
    fp.close
  end

  redirect "/revision/#{otros_params[:revision_sistematica_id]}/busquedas"
end


get '/revision/:id/procesar' do |id|
  revision=Revision_Sistematica[id]
  busquedas=revision.busquedas
  # Primero, procesamos las busquedas individuales
  busquedas.each do |busqueda|
    agregar_mensaje("Archivo de busqueda #{busqueda[:id]} procesada exitosamente") if busqueda.procesar_archivo
  end

  # Segundo, procesamos los canonicos
  busquedas.each do |busqueda|
    agregar_mensaje("Canónicos de #{busqueda[:id]} procesada exitosamente") if busqueda.procesar_canonicos
  end

  redirect back

end


get '/revision/:id/canonicos_documentos_repetidos' do |id|
  @revision=Revision_Sistematica[id]
  @cd_rep_doi=@revision.doi_repetidos
  @cd_hash=@revision.canonicos_documentos.as_hash

  @cd_por_doi=Canonico_Documento.where(:doi => @cd_rep_doi).to_hash_groups(:doi, :id)
  ##$log.info(@cd_por_doi)
  haml %s{revisiones_sistematicas/canonicos_documentos_repetidos}
end


get '/revision/:id/canonicos_documentos_graphml' do |id|
  @revision=Revision_Sistematica[id]

  headers["Content-Disposition"] = "attachment;filename=graphml_revision_#{id}.graphml"

  content_type 'application/graphml+xml'
  graphml=@revision.generar_graphml
  graphml
end



get '/revision/:id/canonicos_documentos' do |id|
  @busqueda=params['busqueda']
  @busqueda=nil if @busqueda.to_s==""
  @pagina=params['pagina'].to_i
  @pagina=1 if @pagina<1
  @cpp=params['cpp']
  @cpp||=20
  @sin_abstract=params['sin_abstract']=='true'
  @solo_registros=params['solo_registros']=='true'
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos

  # Repetidos doi
  @cd_rep_doi=@revision.doi_repetidos
  ##$log.info(@cd_rep_doi)

  @url="/revision/#{id}/canonicos_documentos"
  @cds_pre=@revision.canonicos_documentos

  if @busqueda
    @cds_pre=@cds_pre.where(Sequel.ilike(:title, "%#{@busqueda}%"))
  end
  if @sin_abstract
    @cds_pre=@cds_pre.where(:abstract=>nil)
  end
  if @solo_registros
    @cds_pre=@cds_pre.where(:id=>@ars.cd_reg_id)
  end
  @cds_total=@cds_pre.count


  @max_page=(@cds_total/@cpp.to_f).ceil
  @pagina=1 if @pagina>@max_page

  @cds=@cds_pre.offset((@pagina-1)*@cpp).limit(@cpp).order(:author, :year)

  @ars=AnalisisRevisionSistematica.new(@revision)

  haml %s{revisiones_sistematicas/canonicos_documentos}
end


get '/revision/:id/analisis' do |id|
  @revision=Revision_Sistematica[id]
  redirect to ("/revision/#{@revision[:id]}/#{@revision[:etapa]}")
end


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
  @cds_pre=@revision.canonicos_documentos(:registro)

  @ads=AnalisisDecisionUsuario.new(id,@usuario_id, 'revision_titulo_resumen')

  @cds_pre=@ads.canonicos_documentos

  @decisiones=@ads.decisiones
  if @busqueda

    ##$log.info(@busqueda)
    ##$log.info(@busqueda.class)
    busqueda_int=@busqueda=='--' ? nil :@busqueda
    cd_ids=@ads.decision_por_cd.find_all {|v|
      busqueda_int==v[1]
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


get '/revision/:id/administracion_etapas' do |id|
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  haml %s{revisiones_sistematicas/administracion_etapas}

end


