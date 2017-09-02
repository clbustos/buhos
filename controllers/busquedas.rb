get '/busqueda/:id/editar' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  haml %s{revisiones_sistematicas/busqueda_edicion}
end

get '/busqueda/:id/registros' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  @registros=@busqueda.registros_dataset.order(:author)

  haml %s{revisiones_sistematicas/busqueda_registros}
end


get '/busqueda/:id/referencias' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  @referencias=@busqueda.referencias
  @referencias_con_canonico=@busqueda.referencias.where("canonico_documento_id IS NOT NULL")
  @n_referencias = params['n_referencias'].nil? ? 20 : params['n_referencias']

  @rmc_canonico     = @busqueda.referencias_con_canonico_n(@n_referencias)

  @rmc_sin_canonico = @busqueda.referencias_sin_canonico_n(@n_referencias)

  #$log.info(@rmc_canonico)

  haml %s{revisiones_sistematicas/busqueda_referencias}
end

get '/busqueda/:id/registros/completar_dois' do |id|
  @busqueda=Busqueda[id]
  @registros=@busqueda.registros_dataset
  result=Result.new()
  $db.transaction(:rollback=>:reraise) do
    @registros.each do |registro|
      result.add_result(registro.doi_automatico_crossref)
      if registro.doi
        result.add_result(registro.referencias_automatico_crossref)
      end
    end
  end
  $log.info(result)
  agregar_resultado(result)
  redirect back
end

# Busca en el texto algun indicador de DOI
get '/busqueda/:id/referencias/buscar_dois' do |id|
  exitos=0
  @busqueda=Busqueda[id]
  @referencias=@busqueda.referencias.where(:doi=>nil)
  $db.transaction do
    @referencias.each do |referencia|

      if referencia.texto =~/DOI (\d[^\]]+?)$/
        exitos=+1
        doi=$1
        update_fields={:doi=>doi}
        cd=Canonical_Document[:doi=>doi]
        update_fields[:canonical_document_id]=cd[:id] if cd
        referencia.update(update_fields)
      end
    end
  end
  agregar_mensaje("Actualizados #{exitos} DOI")
  redirect back
end