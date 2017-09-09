require 'net/http'
require 'cgi'


get '/canonico_documento/:id' do |id|
  @cd=Canonico_Documento[id]
  @registros=@cd.registros
  @referencias=@cd.referencias
  if Crossref_Doi[doi_sin_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end

  @referencias_realizadas=@cd.referencias_realizadas
  haml "canonico_documento".to_sym
end


get '/canonico_documento/:id/buscar_referencias_crossref' do |id|
  @cd=Canonico_Documento[id]
  result=Result.new

  @cd.referencias_realizadas.exclude(:doi=>nil).where(:canonico_documento_id=>nil).each do |ref|
      result.add_result(ref.agregar_doi(ref[:doi]))
  end

  agregar_resultado(result)

  redirect back
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
  ##$log.info(@ref_similares)
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

post '/canonico_documento/unir' do
  doi=params['doi']
  pk_ids=params['pk_ids']

  if doi
    cds=Canonico_Documento.where(:doi => doi, :id => pk_ids.split(","))
  end
  if (cds.count>1)
    resultado=Canonico_Documento.unir(cds.map(:id))
  end
  return resultado ? 200 : 500
end


get '/canonicos_documentos/revision/:revision_id/completar_abstract_scopus' do |rev_id|

  @rev=Revision_Sistematica[rev_id]

  @cd_sin_abstract=@rev.canonicos_documentos.where("abstract IS NULL OR abstract=''").select_map(:id)
  agregar_mensaje("Se procesan #{@cd_sin_abstract.count} documentos canonicos")
  @cd_sin_abstract.each do |cd|
    agregar_resultado(Scopus_Abstract.obtener_abstract_cd(cd))
  end
  redirect back
end


get '/canonico_documento/:id/buscar_abstract_scopus' do |id|
  agregar_resultado(Scopus_Abstract.obtener_abstract_cd(id))
  redirect back
end


get '/canonico_documento/:ref_id/limpiar_referencias' do |cd_id|
  Referencia.where(:canonico_documento_id => cd_id).update(:canonico_documento_id => nil, :doi => nil)
  agregar_mensaje("Las referencias para canonico #{cd_id} estan limpias")
  redirect back
end
