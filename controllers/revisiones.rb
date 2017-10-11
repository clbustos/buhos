

get '/revisiones' do 
  error(403) unless permiso('ver_revisiones')
  @usuario=Usuario[session['user_id']]
  @inactivas=params['inactivas']
  @revisiones=Revision_Sistematica.get_revisiones_por_usuario(@usuario.id)
  @revisiones=@revisiones.where(:activa => 1) unless @inactivas
  haml :revisiones
end


get '/revision/nuevo' do
  @revision=Revision_Sistematica.new
  haml %s{revisiones_sistematicas/edicion}
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
  $log.info(otros_params)
  if(id=="")
    revision=Revision_Sistematica.create(
      :nombre=>otros_params[:nombre],
      :grupo_id=>otros_params[:grupo_id],
      :trs_foco_id=>otros_params[:trs_foco_id],
      :trs_objetivo_id=>otros_params[:trs_objetivo_id],
      :trs_perspectiva_id=>otros_params[:trs_perspectiva_id],
      :trs_cobertura_id=>otros_params[:trs_cobertura_id],
      :trs_organizacion_id=>otros_params[:trs_organizacion_id],
      :trs_destinatario_id=>otros_params[:trs_destinatario_id],
      :etapa=>otros_params[:etapa],
      :activa=>otros_params[:activa],
      :n_min_rr_rtr=>otros_params[:n_min_rr_rtr]
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





get '/revision/:id/analisis' do |id|
  @revision=Revision_Sistematica[id]
  redirect to ("/revision/#{@revision[:id]}/#{@revision[:etapa]}")
end


#### DOCUMENTOS CANONICOS #####

get '/revision/:id/canonicos_documentos' do |id|

  @pager=get_pager

  @pager.orden||="n_total_referencias_recibidas__desc"

  @sin_abstract=params['sin_abstract']=='true'
  @solo_registros=params['solo_registros']=='true'
  @revision=Revision_Sistematica[id]
  @ars=AnalisisRevisionSistematica.new(@revision)
  @cd_total_ds=@revision.canonicos_documentos

  # Repetidos doi
  @cd_rep_doi=@revision.doi_repetidos
  ##$log.info(@cd_rep_doi)

  @url="/revision/#{id}/canonicos_documentos"
  @cds_pre=@revision.canonicos_documentos.left_join(@revision.cuenta_referencias_entre_canonicos, cd_id: Sequel[:canonicos_documentos][:id]).left_join(@revision.cuenta_referencias_rtr, cd_destino: :cd_id)



  if @pager.busqueda
    @cds_pre=@cds_pre.where(Sequel.ilike(:title, "%#{@pager.busqueda}%"))
  end
  if @sin_abstract
    @cds_pre=@cds_pre.where(:abstract=>nil)
  end
  if @solo_registros
    @cds_pre=@cds_pre.where(:id=>@ars.cd_reg_id)
  end



  @cds_total=@cds_pre.count


  @pager.max_page=(@cds_total/@pager.cpp.to_f).ceil

#  $log.info(@pager)


  @criterios_orden={:n_referencias_rtr=>"Referencias RTR", :n_total_referencias_recibidas=>"Citado por", :n_total_referencias_hechas=>"Cita a",  :title=>"Título", :year=> "Año", :author=>"Autor"}


  @cds=@pager.ajustar_query(@cds_pre)

  @ars=AnalisisRevisionSistematica.new(@revision)


  haml %s{revisiones_sistematicas/canonicos_documentos}
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





get '/revision/:id/bibtex_resueltos' do  |id|

  @revision=Revision_Sistematica[id]
  @canonicos_resueltos=@revision.canonicos_documentos.where(:id=>@revision.resoluciones_titulo_resumen.where(:resolucion=>'yes').map(:canonico_documento_id) ).order(:author,:year)
  bib=ReferenceIntegrator::BibTex::Writer.generate(@canonicos_resueltos)
  headers["Content-Disposition"] = "attachment;filename=revision_resueltos_#{id}.bib"

  content_type 'text/x-bibtex'
  bib.to_s


end


get '/revision/:id/tags' do |id|
  @revision=Revision_Sistematica[id]

  @etapas_lista={:NIL=>"--Todas--"}.merge(Revision_Sistematica::ETAPAS_NOMBRE)

  @select_etapa=get_xeditable_select(@etapas_lista, "/tags/clases/editar_campo/etapa","select_etapa")
  @select_etapa.nil_value=:NIL
  @tipos_lista={general:"General", documento:"Documento", relacion:"Relación"}

  @select_tipo=get_xeditable_select(@tipos_lista, "/tags/clases/editar_campo/tipo","select_tipo")

  haml %s{revisiones_sistematicas/tags}
end


get '/revision/:id/mensajes' do |id|
  @revision=Revision_Sistematica[id]
  @mensajes_rs=@revision.mensajes_rs_dataset.order(Sequel.desc(:tiempo))
  @mensajes_rs_vistos=Mensaje_Rs_Visto.where(:visto=>true,:m_rs_id=>@mensajes_rs.select_map(:id), :usuario_id=>session['user_id'])

  @usuario=Usuario[session['user_id']]
  haml %s{revisiones_sistematicas/mensajes}
end

post '/revision/:id/mensaje/nuevo' do |id|
  @revision=Revision_Sistematica[id]
  @usuario_id=params['user_id']
  return 404 if @revision.nil? or @usuario_id.nil?
  @asunto=params['asunto']
  @texto=params['texto']
  $db.transaction(:rollback=>:reraise) do
    id=Mensaje_Rs.insert(:revision_sistematica_id=>id, :usuario_desde=>@usuario_id, :respuesta_a=>nil, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto)
    agregar_mensaje("Agregado mensaje #{id}")
  end
  redirect back
end