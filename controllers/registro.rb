get '/registro/:id/buscar_crossref' do |id|
  @reg=Registro[id]
  @respuesta=@reg.crossref_query
  # $log.info(@respuesta)
  haml "revisiones_sistematicas/registro_buscar_crossref".to_sym
end


get '/registro/:id/asignar_doi/:doi' do |id,doi|
  $db.transaction(:rollback=>:reraise) do
    @reg=Registro[id]
    doi=doi.gsub("***","/")
    result=@reg.agregar_doi(doi)
    agregar_resultado(result)
  end
  redirect back
end