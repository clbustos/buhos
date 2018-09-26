# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

require 'net/http'
require 'cgi'


# @!group Canonical documents

# View a Canonical document
get '/canonical_document/:id' do |id|
  halt_unless_auth('canonical_document_view')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd
  @records=@cd.records
  @references=@cd.references
  if CrossrefDoi[doi_without_http(@cd.doi)]
    @cr_doi=@cd.crossref_integrator
  end


  if Pmc_Summary[@cd.pmid]
    @pmc_sum=@cd.pubmed_integrator
  end
  @references_realizadas=@cd.references_performed
  title(t(:canonical_document_title, cd_title:@cd.ref_apa_6))
  haml :canonical_document
end

# Query crossref for all references of a canonical document
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


get '/canonical_document/:id/get_external_data/:type' do |id, type|
  halt_unless_auth('canonical_document_admin')
  @cd=CanonicalDocument[id]
  method="#{type}_integrator".to_sym
  if @cd.respond_to? method
    if @cd.send(method)
      add_message(t("external_data.get_successful", type:type, cd_id:id))
    else
      add_message(t("external_data.get_error", type:type, cd_id:id))
    end

  else
    add_message(t("external_data.dont_know_type"), type: type)
  end

  redirect back
end

# Search references similar to a specific canonical documents, using lexical distance
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

# Merge similar references to a specific canonical document
post '/canonical_document/:id/merge_similar_references' do |id|
  halt_unless_auth('canonical_document_admin')
  @cd=CanonicalDocument[id]
  if !params['reference'].nil?
    references_to_merge=params['reference'].keys
    Reference.where(:id=>references_to_merge).update(:canonical_document_id=>@cd[:id])
    add_message("Se unieron #{references_to_merge.length} references al canonico comun #{@cd[:id]}")
  end
  redirect back
end


# Edit a field on a canonical document
put '/canonical_document/edit_field/:field' do |field|
  halt_unless_auth('canonical_document_admin')
  pk = params['pk']
  value = params['value']

  value=process_abstract_text(value) if field=='abstract'

  @cd=CanonicalDocument[pk]
  @cd.update(field.to_sym=>value.chomp)
  return true
end

# Merge two or more canonical documents
post '/canonical_document/merge' do
  halt_unless_auth('canonical_document_admin')
  doi=params['doi']
  pk_ids=params['pk_ids']

  if doi
    cds=CanonicalDocument.where(:doi => doi, :id => pk_ids.split(","))
  end
  if (cds.count>1)
    resultado=CanonicalDocument.merge(cds.map(:id))
  end
  return resultado ? 200 : 500
end

# Complete all canonical document abstracts on a systematic review, using Scopus
get '/canonical_documents/review/:review_id/complete_abstract_scopus' do |rev_id|
  halt_unless_auth('canonical_document_admin')

  @rev=SystematicReview[rev_id]

  @cd_wo_abstract=@rev.canonical_documents.where(Sequel.lit("abstract IS NULL OR abstract=''")).select_map(:id)
  add_message("Se procesan #{@cd_wo_abstract.count} documentos canonicos")
  @cd_wo_abstract.each do |cd|
    add_result(Scopus_Abstract.get_abstract_cd(cd))
  end
  redirect back
end

# Query Scopus for abstract
get '/canonical_document/:id/search_abstract_scopus' do |id|
  halt_unless_auth('canonical_document_admin')
  add_result(Scopus_Abstract.get_abstract_cd(id))
  redirect back
end

#  Reset all references asssigned to a canonical document
get '/canonical_document/:ref_id/clean_references' do |cd_id|
  halt_unless_auth('canonical_document_admin')
  Reference.where(:canonical_document_id => cd_id).update(:canonical_document_id => nil, :doi => nil)
  add_message("Las references para canonico #{cd_id} estan limpias")
  redirect back
end

# See automatic categories for canonical documents.
# Is very experimental. Works so-so
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

get '/canonical_documents/review/:rev_id/complete_pubmed_pmid' do |rev_id|
  @review=SystematicReview[rev_id]
  halt 500 unless auth_to("pubmed_query")  and ( auth_to('review_admin') or review_belongs_to(@review.id, session['user_id']))
  # Retrieve all doi we can!
  @cd_ds=@review.canonical_documents.exclude(:doi=>nil).where(:pmid=>nil)
  result=PubmedRemote.retrieve_pmid(@cd_ds)
  add_result(result)
  redirect back
end


post '/canonical_document/actions' do
  halt_unless_auth('canonical_document_admin')
  action=params['action']
  halt 500, t(:no_action_specified) unless action
  halt 500, t(:no_canonical_document) if params['canonical_document'].nil?
  cd_ids=params['canonical_document'].keys


  if action=='merge'
    if CanonicalDocument.merge(cd_ids)
      add_message(t(:Canonical_document_merge_successful))
    else
      add_message(t(:Canonical_document_merge_error), :error)
    end
  elsif action=='tags'
    url_action="/review/#{params[:sr_id]}/canonical_documents/tags?"
    url_action+="cd_id="+params['canonical_document'].keys.join(',')
    url_action+="&url_back="+params['url_back']
    url_action+="&user_id="+params['user_id']
    redirect(url(url_action))
  else
    return [500, I18n.t(:that_function_doesn_exists)]
  end
  redirect back
end

# Allocate a canonical document to user, for screening or analyze
post '/canonical_document/user_allocation/:action' do |action|
  halt_unless_auth('review_admin')
  revision=SystematicReview[params['rs_id']]
  cd=CanonicalDocument[params['cd_id']]
  user=User[params['user_id']]
  stage=params['stage']
  return 404 if !revision or !cd or !user or !stage
  a_cd=AllocationCd[:systematic_review_id=>revision[:id],:canonical_document_id=>cd[:id],:user_id=>user[:id], :stage=>stage]
  if action=='allocate'
    if !a_cd
      AllocationCd.insert(:systematic_review_id=>revision[:id],:canonical_document_id=>cd[:id],:user_id=>user[:id],:stage=>stage,:status=>"assigned")
      return 200
    end
  elsif action=='unallocate'
    if a_cd
      a_cd.delete
      return 200
    end
  else
    return [500, I18n.t(:that_function_doesn_exists)]
  end

end


# View raw crossref information using the doi of the canonical document
get '/canonical_document/:id/view_crossref_info' do |id|
  halt_unless_auth('canonical_document_view')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd
  @cr_doi=@cd.crossref_integrator
  @doi_json=CrossrefDoi[doi_without_http(@cd.doi)][:json]
  haml "canonical_documents/view_crossref_info".to_sym
end


# Update information about a canonical document using crossref information
get '/canonical_document/:id/update_using_crossref_info' do |id|
  halt_unless_auth('canonical_document_admin')
  @cd=CanonicalDocument[id]
  #$log.info(@cd)
  raise Buhos::NoCdIdError, id unless @cd
  @cr_doi=@cd.crossref_integrator

  if @cr_doi
    results=@cd.update_info_using_record(@cr_doi)
  else
    results=Result.new
    results.error(I18n::t(:No_DOI_to_obtain_information_from_Crossref))
  end
  $log.info(results)

  add_result results

  redirect back
end


# View raw pubmed information using the pmid of the canonical document
get '/canonical_document/:id/view_pubmed_info' do |id|
  halt_unless_auth('canonical_document_view')
  @cd=CanonicalDocument[id]
  raise Buhos::NoCdIdError, id if !@cd
  @pmc_sum=@cd.pubmed_integrator
  if @cd.pmid
    @xml=Pmc_Summary[@cd.pmid][:xml]
  else
    @xml=nil
  end
  haml "canonical_documents/view_pubmed_info".to_sym
end


# @!endgroup