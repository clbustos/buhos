require 'net/http'
require 'cgi'

get '/referencia/:id/buscar_similar' do |id|
  @ref=Referencia[id]
  @ajax=!params['ajax'].nil?
  @distancia=params['distancia'].to_i
  @distancia=30 if @distancia==0
  @ref_similares=@ref.buscar_similares(@distancia)
  ##$log.info(@ref_similares)
  if @ajax
    haml "revisiones_sistematicas/referencia_buscar_similar".to_sym, :layout=>nil
  else
    haml "revisiones_sistematicas/referencia_buscar_similar".to_sym

  end
end

post '/referencia/:id/unir_referencias_similares' do |id|
  @ref=Referencia[id]
  if (@ref[:canonico_documento_id].nil?)
    raise "No tengo método para unificar sin canonico"
  end
  if !params['referencia'].nil?
    referencias_a_unir=params['referencia'].keys
    Referencia.where(:id=>referencias_a_unir).update(:canonico_documento_id=>@ref[:canonico_documento_id])
    agregar_mensaje("Se unieron las referencias de #{referencias_a_unir.length} referencias a un canonico comun")
  end
  redirect back
end


get '/referencias/buscar_crossref_por_doi/:doi' do |doi|
  doi=doi.gsub("***", "/")
  result=Result.new
  Referencia.where(:doi => doi).each do |ref|
    result.add_result(ref.agregar_doi(doi))
  end

  agregar_resultado(result)
  redirect back
end

get '/referencia/:id/buscar_crossref' do |id|

  @ref=Referencia[id]

  if @ref.doi
    result=Result.new
    result.add_result(@ref.agregar_doi(@ref.doi))
    if result.success?
    agregar_resultado(result)
    redirect back
    else
      agregar_resultado(result)
    end

  end
  @respuesta=@ref.crossref_query
  haml "revisiones_sistematicas/referencia_buscar_crossref".to_sym

end

get '/referencia/:id' do |id|
  @ref=Referencia[id]
  @registros=@ref.registros
  haml :referencia
end

get '/referencia/:id/asignar_doi/:doi' do |id,doi|
  url=params['volver_url']
  @ref=Referencia[id]
  doi=doi.gsub("***","/")
  result=@ref.agregar_doi(doi)
  agregar_resultado(result)
  if url
    redirect to(url)
  else
    redirect back
  end

end


get '/referencias/completar_canonicos' do
  res_c=nil
  $db.transaction(:rollback => :reraise) do
    res=$db["SELECT r.id as referencia_id,cd.id as cd_id	 FROM referencias r INNER  JOIN canonicos_documentos cd ON r.doi=cd.doi WHERE r.doi IS NOT NULL AND r.canonico_documento_id IS NULL 	"]
    res_c=res.count()
    res.each do |row|
      Referencia[row[:referencia_id]].update(:canonico_documento_id => row[:cd_id])
    end
  end
  agregar_mensaje("Se completaron los canonicos para #{res_c} referencias con DOI sin canonicos previos")
  redirect back
end

