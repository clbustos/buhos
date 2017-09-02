require 'net/http'
require 'cgi'


get '/canonico_documento/:id' do |id|
  @cd=Canonico_Documento[id]
  @registros=@cd.registros
  @referencias=@cd.referencias
  if Crossref_Doi[doi_sin_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end
  haml "canonico_documento".to_sym
end


get '/canonico_documento/:id/obtener_crossref' do |id|


  @cd=Canonico_Documento[id]
  if(@cd.crossref_integrator)
    agregar_mensaje("Crossref agregado para #{id}")
  else
    agregar_mensaje("Error al agregar Crossref para #{id}",:error)
  end
  redirect back
end

get '/canonico_documento/:id/buscar_similar' do |id|
  @cd=Canonico_Documento[id]
  @ajax=!params['ajax'].nil?
  @distancia=params['distancia'].to_i
  @distancia=30 if @distancia==0
  @ref_similares=@cd.buscar_referencias_similares(@distancia)
  #$log.info(@ref_similares)
  if @ajax
    haml "canonicos_documentos/referencia_buscar_similar".to_sym, :layout=>nil
  else
    haml "canonicos_documentos/referencia_buscar_similar".to_sym

  end
end

post '/canonico_documento/:id/unir_referencias_similares' do |id|
  @cd=Canonico_Documento[id]
  if !params['referencia'].nil?
    referencias_a_unir=params['referencia'].keys
    Referencia.where(:id=>referencias_a_unir).update(:canonico_documento_id=>@cd[:id])
    agregar_mensaje("Se unieron #{referencias_a_unir.length} referencias al canonico comun #{@cd[:id]}")
  end
  redirect back
end


# Metodo rapido

put '/canonico_documento/editar_campo/:field' do |field|
  pk = params['pk']
  value = params['value']
  @cd=Canonico_Documento[pk]
  @cd.update(field.to_sym=>value.chomp)
  return true
end