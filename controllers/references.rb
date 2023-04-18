# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2023, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

require 'net/http'
require 'cgi'

# @!group References

# View a reference
get '/reference/:id' do |id|
  halt_unless_auth('reference_view')
  @ref=Reference[id]
  raise Buhos::NoReferenceIdError, id unless @ref
  @records=@ref.records
  haml :reference, escape_html: false
end

# Search references similar to a specific one
get '/reference/:id/search_similar' do |id|
  halt_unless_auth('reference_edit')

  @ref=Reference[id]
  raise Buhos::NoReferenceIdError, id unless @ref

  @ajax=!params['ajax'].nil?
  @distancia=params['distancia'].to_i
  @distancia=30 if @distancia==0
  @ref_similares=@ref.search_similars(@distancia)
  ##$log.info(@ref_similares)
  if @ajax
    haml "systematic_reviews/reference_search_similar".to_sym, :layout=>nil
  else
    haml "systematic_reviews/reference_search_similar".to_sym

  end
end


# Merge similar references
post '/reference/:id/merge_similar_references' do |id|
  halt_unless_auth('reference_edit')
  @ref=Reference[id]
  if (@ref[:canonical_document_id].nil?)
    raise "No tengo método para unificar sin canonico"
  end
  if !params['reference'].nil?
    references_a_unir=params['reference'].keys
    Reference.where(:id=>references_a_unir).update(:canonical_document_id=>@ref[:canonical_document_id])
    add_message("Se unieron las references de #{references_a_unir.length} references a un canonico comun")
  end
  redirect back
end

# Query crossref using reference DOI
# @todo check differences with {/reference/:id/search_crossref}
# @deprecated
#get '/references/search_crossref_by_doi/:doi' do |doi|
#  halt_unless_auth('reference_edit')
#  doi=doi.gsub("***", "/")
#  result=Result.new
#  Reference.where(:doi => doi).each do |ref|
#    result.add_result(ref.add_doi(doi))
#  end
#
#  add_result(result)
#  redirect back
#end

# Query one or more references on Crossref using their DOIs
#

post '/references/search_crossref_by_doi' do
  halt_unless_auth('reference_edit')
  dois=params['doi']
  result=Result.new
  #$log.info("Procesando :#{dois}")

  if !dois
    result.error(I18n::t(:one_or_more_DOI_needed))
  else
    dois.each do |doi|
      #$log.info("Buscando:#{doi}")
      Reference.where(:doi=>doi).each do |ref|
        result.add_result(ref.add_doi(doi))
        #$log.info(result)
      end
    end
  end
  add_result(result)
  redirect back
end


# Query crossref for a specific references
# @todo check differences with {'/references/search_crossref_by_doi/:doi}
get '/reference/:id/search_crossref' do |id|
  halt_unless_auth('reference_edit')
  @ref=Reference[id]

  raise Buhos::NoReferenceIdError, id if !@ref

  if @ref.doi
    result=Result.new
    result.add_result(@ref.add_doi(@ref.doi))

    if result.success?
      add_result(result)
      redirect back
    else
      add_result(result)
    end
  end

  @response_crossref=@ref.crossref_query
  $log.info(@bib_int)
#  $log.info(@response_crossref)

  haml "systematic_reviews/reference_search_crossref".to_sym

end



get '/reference/:id/assign_doi/:doi' do |id,doi|
  halt_unless_auth('reference_edit')
  url=params['volver_url']
  @ref=Reference[id]
  doi=doi.gsub("***","/")
  result=@ref.add_doi(doi)
  add_result(result)
  if url
    redirect to(url)
  else
    redirect back
  end

end

post '/reference/assign_canonical_document' do
  halt_unless_auth('reference_edit')
  @canonical_document=CanonicalDocument[params['cd_id']]
  @reference=Reference[params['ref_id']]

  raise Buhos::NoReferenceIdError, params['ref_id'] if !@reference
  raise Buhos::NoCdIdError, params['cd_id'] if !@canonical_document

  $db.transaction do
    @reference.update(:canonical_document_id=>@canonical_document.id)
    add_message(t("canonical_document.assigned_to_reference", cd_title:@canonical_document.title, reference:@reference.text))
  end

  redirect back
end

# @!endgroup