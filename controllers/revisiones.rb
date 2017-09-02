

get '/revisiones' do 
  error(403) unless permiso('ver_revisiones')
  @usuario=Usuario[session['user_id']]
  @revisiones=Revision_Sistematica.get_revisiones_por_usuario(@usuario.id)
  haml :revisiones
end

get "/revision/:id" do |id|
  @revision=Revision_Sistematica[id]
  @nombres_trs=@revision.get_nombres_trs
  #$log.info(@nombres_trs)
  haml %s{revisiones_sistematicas/ver}
end

get "/revision/:id/edicion" do |id|
  @revision=Revision_Sistematica[id]

  haml %s{revisiones_sistematicas/edicion}
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
  #$log.info(otros_params)
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