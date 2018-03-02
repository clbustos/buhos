get '/search/:id' do |id|
  halt_unless_auth('search_view')

  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @review=@search.systematic_review
  haml %s{searches/search_view}
end

get '/search/:id/edit' do |id|
  halt_unless_auth('search_edit')

  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @review=@search.systematic_review
  haml %s{searches/search_edit}
end

get '/search/:id/file/download' do |id|
  halt_unless_auth('search_view')

  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  if @search[:filename].nil?
    return 404
  else
    headers["Content-Disposition"] = "attachment; filename=#{@search[:filename]}"
    content_type @search[:filetype]
    @search[:file_body]
  end

end

get '/search/:id/records' do |id|
  halt_unless_auth('search_view')
  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @review=@search.systematic_review
  @records=@search.records_dataset.order(:author)

  haml %s{searches/search_records}
end


get '/search/:id/references' do |id|
  halt_unless_auth('search_view')
  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @review=@search.systematic_review
  @references=@search.references
  @references_con_canonico=@search.references.where(Sequel.lit("canonical_document_id IS NOT NULL"))
  @references_solo_doi=@search.references.where(Sequel.lit("canonical_document_id IS NULL AND doi IS NOT NULL"))
  @n_references = params['n_references'].nil? ? 20 : params['n_references']

  @rmc_canonico     = @search.references_with_canonical_n(@n_references)

  @rmc_sin_canonico = @search.references_sin_canonico_n(@n_references)

  @rmc_sin_canonico_con_doi = @search.references_sin_canonico_con_doi_n(@n_references)

  ##$log.info(@rmc_canonico)

  haml %s{searches/search_references}
end


# Completa la información desde Crossref para cada registro
get '/search/:id/records/complete_doi' do |id|
  halt_unless_auth('search_edit')
  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @records=@search.records_dataset
  rcp=RecordCrossrefProcessor.new(@records,$db)
  add_result(rcp.result)
  redirect back
end


# Busca en el text algun indicador de DOI
get '/search/:id/references/search_doi' do |id|
  halt_unless_auth('search_edit')
  exitos=0
  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @references=@search.references.where(:doi=>nil)
  $db.transaction do
    @references.each do |reference|
      rp=ReferenceProcessor.new(reference)
      exitos+=1 if rp.process_doi
    end
  end
  add_message(I18n::t(:Search_add_doi_references, :count=>exitos))
  redirect back
end

get '/search/:id/references/generate_canonical_doi/:n' do |id, n|
  halt_unless_auth('search_edit')
  search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  col_dois=search.references_sin_canonico_con_doi_n(n)
  result=Result.new
  col_dois.each do |col_doi|
    Reference.where(:doi => col_doi[:doi]).each do |ref|
      result.add_result(ref.add_doi(col_doi[:doi]))
    end
  end
  add_result(result)
  redirect back
end


post '/search/update' do
  halt_unless_auth('search_edit')
  id=params['search_id']
  otros_params=params
  otros_params.delete("search_id")
  otros_params.delete("captures")

  archivo=otros_params.delete("file")
  #No nulos

  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
  #  aa=SystematicReview.new

    if params['bibliographic_database_id'].nil?
      add_message(I18n::t(:No_empty_bibliographic_database_on_search), :error)
    else


    if id==""
      search=Search.create(
          :systematic_review_id=>otros_params[:systematic_review_id],
          :source=>otros_params[:source],
          :bibliographic_database_id=>otros_params[:bibliographic_database_id],
          :date_creation=>otros_params[:date_creation],
          :search_criteria=>otros_params[:search_criteria],
          :description=>otros_params[:description]
      )
    else
      search=Search[id]
      search.update(otros_params)
    end

    if archivo
      fp=File.open(archivo[:tempfile],"rb")
      search.update(:file_body=>fp.read, :filetype=>archivo[:type],:filename=>archivo[:filename])
      fp.close
    end
  end

  redirect "/review/#{otros_params[:systematic_review_id]}/searches"
end



post '/searches/update_batch' do
  halt_unless_auth('search_edit')
  #$log.info(params)
  if params["action"].nil?
    add_message(I18n::t(:No_valid_action), :error)
  elsif params['search'].nil?
    add_message(I18n::t(:No_search_selected), :error)
  else
    searches=Search.where(:id=>params['search'])
    if params['action']=='valid'
      searches.update(:valid=>true)
    elsif params['action']=='invalid'
      searches.update(:valid=>false)
    elsif params['action']=='delete'
      searches.delete()
    elsif params['action']=='process'
      results=Result.new
      searches.each do |search|
        sp=SearchProcessor.new(search)
        results.add_result(sp.result)
      end
      add_result(results)
    else
      add_message(I18n::t(:Action_not_defined), :error)
    end
  end
  redirect params['url_back']
end


get '/search/:id/validate' do |id|
  halt_unless_auth('search_edit')
  Search[id].update(:valid=>true)
  add_message(I18n::t(:Search_marked_as_valid))
  redirect back
end

get '/search/:id/invalidate' do |id|
  halt_unless_auth('search_edit')
  Search[id].update(:valid=>false)
  add_message(I18n::t(:Search_marked_as_invalid))
  redirect back
end