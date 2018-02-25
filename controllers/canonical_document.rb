require 'net/http'
require 'cgi'


get '/canonical_document/:id' do |id|
  @cd=Canonico_Documento[id]
  raise Buhos::NoCdIdError, id if !@cd
  @registros=@cd.registros
  @referencias=@cd.referencias
  if Crossref_Doi[doi_sin_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end

  @referencias_realizadas=@cd.referencias_realizadas
  title(t(:Canonical_document_title, cd_name:@cd.ref_apa_6))
  haml :canonical_document
end


get '/canonical_document/:id/search_crossref_references' do |id|
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

  add_result(result)
  redirect back
end

get '/canonical_document/:id/get_crossref_data' do |id|


  @cd=Canonico_Documento[id]
  if(@cd.crossref_integrator)
    agregar_mensaje("Crossref agregado para #{id}")
  else
    agregar_mensaje("Error al agregar Crossref para #{id}",:error)
  end
  redirect back
end

get '/canonical_document/:id/search_similar' do |id|
  @cd=Canonico_Documento[id]
  raise Buhos::NoCdIdError, id if !@cd

  @ajax=!params['ajax'].nil?
  @distancia=params['distancia'].to_i
  @distancia=30 if @distancia==0
  @ref_similares=@cd.buscar_referencias_similares(@distancia)
  ##$log.info(@ref_similares)
  if @ajax
    haml "canonical_documents/reference_search_similar".to_sym, :layout=>nil
  else
    haml "canonical_documents/reference_search_similar".to_sym

  end
end

post '/canonical_document/:id/merge_similar_references' do |id|
  @cd=Canonico_Documento[id]
  if !params['referencia'].nil?
    referencias_a_unir=params['referencia'].keys
    Referencia.where(:id=>referencias_a_unir).update(:canonico_documento_id=>@cd[:id])
    agregar_mensaje("Se unieron #{referencias_a_unir.length} referencias al canonico comun #{@cd[:id]}")
  end
  redirect back
end


# Metodo rapido

put '/canonical_document/edit_field/:field' do |field|
  pk = params['pk']
  value = params['value']
  @cd=Canonico_Documento[pk]
  @cd.update(field.to_sym=>value.chomp)
  return true
end

post '/canonical_document/merge' do
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


get '/canonical_documents/review/:revision_id/complete_abstract_scopus' do |rev_id|

  @rev=Revision_Sistematica[rev_id]

  @cd_sin_abstract=@rev.canonicos_documentos.where(Sequel.lit("abstract IS NULL OR abstract=''")).select_map(:id)
  agregar_mensaje("Se procesan #{@cd_sin_abstract.count} documentos canonicos")
  @cd_sin_abstract.each do |cd|
    add_result(Scopus_Abstract.obtener_abstract_cd(cd))
  end
  redirect back
end


get '/canonical_document/:id/search_abstract_scopus' do |id|
  add_result(Scopus_Abstract.obtener_abstract_cd(id))
  redirect back
end


get '/canonical_document/:ref_id/clean_references' do |cd_id|
  Referencia.where(:canonico_documento_id => cd_id).update(:canonico_documento_id => nil, :doi => nil)
  agregar_mensaje("Las referencias para canonico #{cd_id} estan limpias")
  redirect back
end


get '/canonical_documents/review/:rev_id/automatic_categories' do |rev_id|
  @revision=Revision_Sistematica[rev_id]
  @cd_hash=@revision.cd_hash
  #require 'categorize'
  #modelo=Categorize::Models::Cluster.new
  #modelo.num_clusters = 20
  @categorizador=CategorizerSr.new(@revision, nil)
  haml %s{systematic_reviews/canonical_documents_automatic_categories}
end

post '/canonical_document/user_assignation/:accion' do |accion|
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

get '/canonical_document/:id/view_doi' do |id|
  @cd=Canonico_Documento[id]
  raise Buhos::NoCdIdError, id if !@cd
  @cr_doi=@cd.crossref_integrator
  @doi_json=Crossref_Doi[doi_sin_http(@cd.doi)][:json]
  haml "canonical_documents/view_doi".to_sym
end