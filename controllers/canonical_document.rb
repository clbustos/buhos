require 'net/http'
require 'cgi'


get '/canonical_document/:id' do |id|
  halt_unless_auth('canonical_document_view')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd
  @records=@cd.records
  @references=@cd.references
  if CrossrefDoi[doi_without_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end

  @references_realizadas=@cd.references_performed
  title(t(:canonical_document_title, cd_title:@cd.ref_apa_6))
  haml :canonical_document
end


get '/canonical_document/:id/search_crossref_references' do |id|
  halt_unless_auth('canonical_document_admin')

  @cd=CanonicalDocument[id]
  result=Result.new
  references=@cd.references_performed.exclude(:doi=>nil).where(:canonical_document_id=>nil)
  if references.empty?
    result.info(I18n::t(:no_references_to_search_on_crossref))
  else
    references.each do |ref|
      result.add_result(ref.add_doi(ref[:doi]))
    end
  end

  add_result(result)
  redirect back
end

get '/canonical_document/:id/get_crossref_data' do |id|
  halt_unless_auth('canonical_document_admin')

  @cd=CanonicalDocument[id]
  if(@cd.crossref_integrator)
    add_message("Crossref agregado para #{id}")
  else
    add_message("Error al agregar Crossref para #{id}", :error)
  end
  redirect back
end

get '/canonical_document/:id/search_similar' do |id|
  halt_unless_auth('canonical_document_admin')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd

  @ajax=!params['ajax'].nil?
  @distancia=params['distancia'].to_i
  @distancia=30 if @distancia==0
  @ref_similares=@cd.buscar_references_similares(@distancia)
  ##$log.info(@ref_similares)
  if @ajax
    haml "canonical_documents/reference_search_similar".to_sym, :layout=>nil
  else
    haml "canonical_documents/reference_search_similar".to_sym

  end
end

post '/canonical_document/:id/merge_similar_references' do |id|
  halt_unless_auth('canonical_document_admin')
  @cd=CanonicalDocument[id]
  if !params['reference'].nil?
    references_a_unir=params['reference'].keys
    Reference.where(:id=>references_a_unir).update(:canonical_document_id=>@cd[:id])
    add_message("Se unieron #{references_a_unir.length} references al canonico comun #{@cd[:id]}")
  end
  redirect back
end


# Metodo rapido

put '/canonical_document/edit_field/:field' do |field|
  halt_unless_auth('canonical_document_admin')
  pk = params['pk']
  value = params['value']
  @cd=CanonicalDocument[pk]
  @cd.update(field.to_sym=>value.chomp)
  return true
end

post '/canonical_document/merge' do
  halt_unless_auth('canonical_document_admin')
  doi=params['doi']
  pk_ids=params['pk_ids']

  if doi
    cds=CanonicalDocument.where(:doi => doi, :id => pk_ids.split(","))
  end
  if (cds.count>1)
    resultado=CanonicalDocument.unir(cds.map(:id))
  end
  return resultado ? 200 : 500
end


get '/canonical_documents/review/:review_id/complete_abstract_scopus' do |rev_id|
  halt_unless_auth('canonical_document_admin')

  @rev=SystematicReview[rev_id]

  @cd_wo_abstract=@rev.canonical_documents.where(Sequel.lit("abstract IS NULL OR abstract=''")).select_map(:id)
  add_message("Se procesan #{@cd_wo_abstract.count} documentos canonicos")
  @cd_wo_abstract.each do |cd|
    add_result(Scopus_Abstract.obtener_abstract_cd(cd))
  end
  redirect back
end


get '/canonical_document/:id/search_abstract_scopus' do |id|
  halt_unless_auth('canonical_document_admin')
  add_result(Scopus_Abstract.obtener_abstract_cd(id))
  redirect back
end


get '/canonical_document/:ref_id/clean_references' do |cd_id|
  halt_unless_auth('canonical_document_admin')
  Reference.where(:canonical_document_id => cd_id).update(:canonical_document_id => nil, :doi => nil)
  add_message("Las references para canonico #{cd_id} estan limpias")
  redirect back
end


get '/canonical_documents/review/:rev_id/automatic_categories' do |rev_id|
  halt_unless_auth('canonical_document_view')
  @review=SystematicReview[rev_id]
  @cd_hash=@review.cd_hash
  #require 'categorize'
  #modelo=Categorize::Models::Cluster.new
  #modelo.num_clusters = 20
  @categorizador=CategorizerSr.new(@review, nil)
  haml %s{systematic_reviews/canonical_documents_automatic_categories}
end

post '/canonical_document/user_assignation/:accion' do |accion|
  halt_unless_auth('review_admin')
  revision=SystematicReview[params['rs_id']]
  cd=CanonicalDocument[params['cd_id']]
  user=User[params['user_id']]
  stage=params['stage']
  return 404 if !revision or !cd or !user or !stage
  a_cd=AllocationCd[:systematic_review_id=>revision[:id],:canonical_document_id=>cd[:id],:user_id=>user[:id], :stage=>stage]
  if accion=='asignar'
    if !a_cd
      AllocationCd.insert(:systematic_review_id=>revision[:id],:canonical_document_id=>cd[:id],:user_id=>user[:id],:stage=>stage,:status=>"assigned")
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
  halt_unless_auth('canonical_document_view')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd
  @cr_doi=@cd.crossref_integrator
  @doi_json=CrossrefDoi[doi_without_http(@cd.doi)][:json]
  haml "canonical_documents/view_doi".to_sym
end