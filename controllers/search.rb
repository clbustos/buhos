# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Searches

# View search
get '/search/:id' do |id|
  halt_unless_auth('search_view')

  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @review=@search.systematic_review
  haml %s{searches/search_view}
end

# Form to edit a search
get '/search/:id/edit' do |id|
  halt_unless_auth('search_edit')

  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @review=@search.systematic_review
  haml %s{searches/search_edit}
end


# Download the file allocated to a search
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

# List of records for a search
get '/search/:id/records' do |id|
  halt_unless_auth('search_view')
  @search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @review=@search.systematic_review
  @records=@search.records_dataset.order(:author)

  haml %s{searches/search_records}
end


# Retrieve a single record from a search
get '/search/:s_id/record/:r_id' do |s_id, r_id|
  halt_unless_auth('search_view')
  @search=Search[s_id]
  raise Buhos::NoSearchIdError, s_id if @search.nil?
  @reg=Record[r_id]
  raise Buhos::NoRecordIdError, r_id if @reg.nil?
  @review=@search.systematic_review
  @references=@reg.references
  haml "record".to_sym

end

# List of references for a search
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

  @rmc_sin_canonico = @search.references_wo_canonical_n(@n_references)

  @rmc_sin_canonico_con_doi = @search.references_wo_canonical_w_doi_n(@n_references)

  ##$log.info(@rmc_canonico)

  haml %s{searches/search_references}
end


# Complete the information for each Record, using Crossref
get '/search/:id/records/complete_doi' do |id|
  halt_unless_auth('search_edit')
  @search=Search[id]

  raise Buhos::NoSearchIdError, id if @search.nil?

  @records=@search.records_dataset

  rcp=RecordCrossrefProcessor.new(@records,$db)

  $log.info(rcp.result)
  add_result(rcp.result)
  redirect back
end


# Search on each reference a posible DOI string
# @todo: Should be integrated on a better way
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

# Join canonicals to references
get '/search/:id/references/generate_canonical_doi/:n' do |id, n|
  halt_unless_auth('search_edit')
  search=Search[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  col_dois=search.references_wo_canonical_w_doi_n(n)
  result=Result.new
  col_dois.each do |col_doi|
    Reference.where(:doi => col_doi[:doi]).each do |ref|
      result.add_result(ref.add_doi(col_doi[:doi]))
    end
  end
  add_result(result)
  redirect back
end

# Update or create a search
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
            :description=>otros_params[:description],
            :search_type=>otros_params[:search_type]
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

      if search.is_type?(:bibliographic_file)
        sp=BibliographicFileProcessor.new(search)
        add_result(sp.result)
        unless sp.error.nil?
          add_message(sp.error, :error)
          search.delete
        end
      end

    end
  redirect "/review/#{otros_params[:systematic_review_id]}/dashboard"
end


# Update actions for searchs: valid, invalid, delete
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
      searches.each do |search| search.delete() end
    elsif params['action']=='process'
      results=Result.new
      searches.each do |search|
        sp=BibliographicFileProcessor.new(search)
        results.add_result(sp.result)
      end
      add_result(results)
    else
      add_message(I18n::t(:Action_not_defined), :error)
    end
  end
  redirect params['url_back']
end

# Validate a specific search
get '/search/:id/validate' do |id|
  halt_unless_auth('search_edit')
  Search[id].update(:valid=>true)
  add_message(I18n::t(:Search_marked_as_valid))
  redirect back
end

# Invalidate a specific search
get '/search/:id/invalidate' do |id|
  halt_unless_auth('search_edit')
  Search[id].update(:valid=>false)
  add_message(I18n::t(:Search_marked_as_invalid))
  redirect back
end


# @!endgroup
