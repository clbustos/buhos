get '/revision/:id/busquedas' do |id|
  error(403) unless permiso('busqueda_revision_ver')
  @revision=Revision_Sistematica[id]
  @busquedas=@revision.busquedas
  @header=t_systematic_review_title(@revision[:nombre], :systematic_review_searchs)

  @url_back="/revision/#{id}/busquedas"
  haml "revisiones_sistematicas/busquedas".to_sym
end

get '/revision/:id/busquedas/user/:user_id' do |id,user_id|
  error(403) unless permiso('busqueda_revision_ver')
  @revision=Revision_Sistematica[id]

  @header=t_systematic_review_title(@revision[:nombre], t(:searchs_user, :user_name=>Usuario[user_id][:nombre]), false)
  @url_back="/revision/#{id}/busquedas/user/#{user_id}"
  @busquedas=@revision.busquedas_dataset.where(:user_id=>user_id)
  haml "revisiones_sistematicas/busquedas".to_sym
end





get '/revision/:id/busqueda/nuevo' do |id|
  error(403) unless permiso('busqueda_revision_crear')
  require 'date'

  @revision=Revision_Sistematica[id]
  @header=t_systematic_review_title(@revision[:nombre], :New_search)

  @busqueda=Busqueda.new(:user_id=>session['user_id'], :valid=>false, :fecha=>Date.today)
  @usuario=Usuario[session['user_id']]
  haml "busquedas/busqueda_edicion".to_sym
end

post '/revision/busqueda/actualizar' do
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

  if !permiso('busqueda_revision_crear')
    agregar_mensaje(I18n::t(:Not_allowed_with_user_permissions),:error)
  elsif params['base_bibliografica_id'].nil?
    agregar_mensaje(I18n::t(:No_empty_bibliographic_database_on_search),:error)
  else


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

    if archivo
      fp=File.open(archivo[:tempfile],"rb")
      busqueda.update(:archivo_cuerpo=>fp.read, :archivo_tipo=>archivo[:type],:archivo_nombre=>archivo[:filename])
      fp.close
    end
  end

  redirect "/revision/#{otros_params[:revision_sistematica_id]}/busquedas"
end

# To process all searchs on a systematic review
get '/revision/:id/busquedas/procesar' do |id|
  revision=Revision_Sistematica[id]
  busquedas=revision.busquedas
  # Primero, procesamos las busquedas individuales
  results=Result.new
  busquedas.each do |busqueda|
    sp=SearchProcessor.new(busqueda)
    results.add_result(sp.result)
  end
  agregar_resultado(results)
  redirect back

end


get '/revision/:rs_id/busquedas/comparar_registros' do |rs_id|
  @revision=Revision_Sistematica[rs_id]
  return 404 if !@revision
  @cds={}
  @errores=[]
  @busquedas_id=@revision.busquedas_dataset.map(:id)
  n_busquedas=@busquedas_id.length
  @revision.busquedas.each do |busqueda|
    busqueda.registros.each do |registro|
      rcd_id=registro[:canonico_documento_id]

      if rcd_id
        @cds[rcd_id]||={:busquedas=>{}}
        @cds[rcd_id][:busquedas][busqueda[:id]]=true
      else
        errores.push(registro[:id])
      end
    end
  end
  @cds_o=Canonico_Documento.where(:id=>@cds.keys).to_hash(:id)
  @cds_ordenados=@cds.sort_by {|key,a|
    #$log.info(@busquedas_id)
    #$log.info(a)
    base_n=1+a[:busquedas].length*(2**(n_busquedas+1))
    #$log.info("Base:#{base_n}")
    sec_n=(0...n_busquedas).inject(0) {|total,aa|  total+=(a[:busquedas][@busquedas_id[aa]].nil? ) ? 0 : 2**aa;total}
    #$log.info("Sec:#{sec_n}")
    base_n+sec_n
  }

  haml "busquedas/busquedas_comparar_registros".to_sym
end