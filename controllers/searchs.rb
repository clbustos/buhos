get '/search/:id' do |id|
  halt_unless_auth('search_view')

  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @revision=@search.revision_sistematica
  haml %s{searchs/search_view}
end

get '/search/:id/edit' do |id|
  halt_unless_auth('search_edit')

  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  @revision=@search.revision_sistematica
  haml %s{searchs/search_edit}
end

get '/search/:id/file/download' do |id|
  halt_unless_auth('search_view')

  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?
  if @search[:archivo_nombre].nil?
    return 404 if archivo.nil?
  else
    headers["Content-Disposition"] = "attachment; filename=#{@search[:archivo_nombre]}"
    content_type @search[:archivo_tipo]
    @search[:archivo_cuerpo]
  end

end

get '/search/:id/records' do |id|
  halt_unless_auth('search_view')
  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @revision=@search.revision_sistematica
  @registros=@search.registros_dataset.order(:author)

  haml %s{searchs/search_records}
end


get '/search/:id/references' do |id|
  halt_unless_auth('search_view')
  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @revision=@search.revision_sistematica
  @referencias=@search.referencias
  @referencias_con_canonico=@search.referencias.where(Sequel.lit("canonico_documento_id IS NOT NULL"))
  @referencias_solo_doi=@search.referencias.where(Sequel.lit("canonico_documento_id IS NULL AND doi IS NOT NULL"))
  @n_referencias = params['n_referencias'].nil? ? 20 : params['n_referencias']

  @rmc_canonico     = @search.referencias_con_canonico_n(@n_referencias)

  @rmc_sin_canonico = @search.referencias_sin_canonico_n(@n_referencias)

  @rmc_sin_canonico_con_doi = @search.referencias_sin_canonico_con_doi_n(@n_referencias)

  ##$log.info(@rmc_canonico)

  haml %s{searchs/search_references}
end


# Completa la información desde Crossref para cada registro
get '/search/:id/records/complete_doi' do |id|
  halt_unless_auth('search_edit')
  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @registros=@search.registros_dataset
  rcp=RecordCrossrefProcessor.new(@registros,$db)
  add_result(rcp.result)
  redirect back
end


# Busca en el texto algun indicador de DOI
get '/search/:id/references/search_doi' do |id|
  halt_unless_auth('search_edit')
  exitos=0
  @search=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  @referencias=@search.referencias.where(:doi=>nil)
  $db.transaction do
    @referencias.each do |referencia|
      rp=ReferenceProcessor.new(referencia)
      exitos+=1 if rp.process_doi
    end
  end
  agregar_mensaje(I18n::t(:Search_add_doi_references, :count=>exitos))
  redirect back
end

get '/search/:id/references/generate_canonical_doi/:n' do |id, n|
  halt_unless_auth('search_edit')
  busqueda=Busqueda[id]
  raise Buhos::NoSearchIdError, id if @search.nil?

  col_dois=busqueda.referencias_sin_canonico_con_doi_n(n)
  result=Result.new
  col_dois.each do |col_doi|
    Referencia.where(:doi => col_doi[:doi]).each do |ref|
      result.add_result(ref.add_doi(col_doi[:doi]))
    end
  end
  add_result(result)
  redirect back
end


post '/search/update' do
  halt_unless_auth('search_edit')
  id=params['busqueda_id']
  otros_params=params
  otros_params.delete("busqueda_id")
  otros_params.delete("captures")

  archivo=otros_params.delete("archivo")
  #No nulos

  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }
  #  aa=Revision_Sistematica.new

  if params['base_bibliografica_id'].nil?
    agregar_mensaje(I18n::t(:No_empty_bibliographic_database_on_search),:error)
  else


    if id==""
      busqueda=Busqueda.create(
          :revision_sistematica_id=>otros_params[:revision_sistematica_id],
          :source=>otros_params[:source],
          :base_bibliografica_id=>otros_params[:base_bibliografica_id],
          :fecha=>otros_params[:fecha],
          :criterio_busqueda=>otros_params[:criterio_busqueda],
          :descripcion=>otros_params[:descripcion]
      )
    else
      busqueda=Busqueda[id]
      busqueda.update(otros_params)
    end

    if archivo
      fp=File.open(archivo[:tempfile],"rb")
      busqueda.update(:archivo_cuerpo=>fp.read, :archivo_tipo=>archivo[:type],:archivo_nombre=>archivo[:filename])
      fp.close
    end
  end

  redirect "/review/#{otros_params[:revision_sistematica_id]}/searchs"
end



post '/searchs/update_batch' do
  halt_unless_auth('search_edit')
  #$log.info(params)
  if params["action"].nil?
    agregar_mensaje(I18n::t(:No_valid_action), :error)
  elsif params['search'].nil?
    agregar_mensaje(I18n::t(:No_search_selected), :error)
  else
    searchs=Busqueda.where(:id=>params['search'])
    if params['action']=='valid'
      searchs.update(:valid=>true)
    elsif params['action']=='invalid'
      searchs.update(:valid=>false)
    elsif params['action']=='delete'
      searchs.delete()
    elsif params['action']=='process'
      results=Result.new
      searchs.each do |search|
        sp=SearchProcessor.new(search)
        results.add_result(sp.result)
      end
      add_result(results)
    else
      agregar_mensaje(I18n::t(:Action_not_defined), :error)
    end
  end
  redirect params['url_back']
end


get '/search/:id/validate' do |id|
  halt_unless_auth('search_edit')
  Busqueda[id].update(:valid=>true)
  agregar_mensaje(I18n::t(:Search_marked_as_valid))
  redirect back
end

get '/search/:id/invalidate' do |id|
  halt_unless_auth('search_edit')
  Busqueda[id].update(:valid=>false)
  agregar_mensaje(I18n::t(:Search_marked_as_invalid))
  redirect back
end