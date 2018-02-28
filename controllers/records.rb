get '/record/:id' do |id|
  @reg=Registro[id]
  @referencias=@reg.referencias
  haml "record".to_sym
end


get '/record/:id/search_crossref' do |id|
  @reg=Registro[id]
  @respuesta=@reg.crossref_query
  # #$log.info(@respuesta)
  haml "systematic_reviews/record_search_crossref".to_sym
end


get '/record/:id/assign_doi/:doi' do |id,doi|

  $db.transaction(:rollback=>:reraise) do
    @reg=Registro[id]
    doi=doi.gsub("***","/")
    result=@reg.add_doi(doi)
    add_result(result)
  end
  redirect back
end


post '/record/:id/manual_references' do |id|
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