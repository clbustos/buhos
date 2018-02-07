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
  title(t(:Canonical_document_title, cd_name:@cd.ref_apa_6))
  haml "canonico_documento".to_sym
end


get '/canonico_documento/:id/buscar_referencias_crossref' do |id|
  @cd=Canonico_Documento[id]
  result=Result.new
  referencias=@cd.referencias_realizadas.exclude(:doi=>nil).where(:canonico_documento_id=>nil)
  if referencias.empty?
    result.info(I18n::t(:no_references_to_search_on_crossref))
  else
    referencias.each do |ref|
      result.add_result(ref.agregar_doi(ref[:doi]))
    end
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

  @cd_sin_abstract=@rev.canonicos_documentos.where(Sequel.lit("abstract IS NULL OR abstract=''")).select_map(:id)
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


get '/canonicos_documentos/revision/:rev_id/categorizar_automatico' do |rev_id|
  @revision=Revision_Sistematica[rev_id]
  @cd_hash=@revision.cd_hash
  #require 'categorize'
  #modelo=Categorize::Models::Cluster.new
  #modelo.num_clusters = 20
  @categorizador=Categorizador_RS.new(@revision,nil)
  haml %s{revisiones_sistematicas/canonicos_documentos_categorias_automaticas}
end

post '/canonico_documento/asignacion_usuario/:accion' do |accion|
  revision=Revision_Sistematica[params['rs_id']]
  cd=Canonico_Documento[params['cd_id']]
  user=Usuario[params['user_id']]
  stage=params['stage']
  return 404 if !revision or !cd or !user or !stage
  a_cd=Asignacion_Cd[:revision_sistematica_id=>revision[:id],:canonico_documento_id=>cd[:id],:usuario_id=>user[:id], :etapa=>stage]
  if accion=='asignar'
    if !a_cd
      Asignacion_Cd.insert(:revision_sistematica_id=>revision[:id],:canonico_documento_id=>cd[:id],:usuario_id=>user[:id],:etapa=>stage,:estado=>"assigned")
      return 200
    end
  elsif accion=='desasignar'
    if a_cd
      a_cd.delete
      return 200
    end
  else
    return [500, I18n.t(:that_function_doesn_exists)]
  end

end

get '/canonico_documento/:id/view_doi' do |id|
  @cd=Canonico_Documento[id]
  return 404 if @cd.nil?
  @cr_doi=@cd.crossref_integrator
  @doi_json=Crossref_Doi[doi_sin_http(@cd.doi)][:json]
  haml "canonicos_documentos/view_doi".to_sym
end