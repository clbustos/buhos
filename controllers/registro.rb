get '/registro/:id' do |id|
  @reg=Registro[id]
  @referencias=@reg.referencias
  haml "registro".to_sym
end


get '/registro/:id/buscar_crossref' do |id|
  @reg=Registro[id]
  @respuesta=@reg.crossref_query
  # #$log.info(@respuesta)
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


post '/registro/:id/referencias_manuales' do |id|
  ref_man=params['referencia_manual']
  $db.transaction(:rollback => :reraise) do
    if ref_man
      partes=ref_man.split("\n").map {|v| v.strip.gsub("[ Links ]", "").gsub(/\s+/, ' ')}.find_all {|v| v!=""}
      partes.each do |parte|
        ref=Referencia.get_by_text_and_doi(parte, nil, true)
        ref_reg=Referencia_Registro.where(:registro_id => id, :referencia_id => ref[:id]).first
        unless ref_reg
          Referencia_Registro.insert(:registro_id => id, :referencia_id => ref[:id])
        end
      end
      agregar_mensaje("Agregadas #{partes.count} referencias")
    end
  end
  redirect back
end