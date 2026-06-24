require 'json'

# @!group Documentos favoritos

# Listar favoritos en categorías públicas
get '/favorites' do
  halt_unless_auth('review_view')

  @favorite_groups = FavoriteGroup.where(is_public: true).order(:name).all
  group_ids = @favorite_groups.collect(&:id)
  @favorite_documents_by_group = {}
  @favorite_canonical_documents = {}
  @favorite_group_users = {}

  unless group_ids.empty?
    favorite_documents = FavoriteDocument.where(activo: true, group_id: group_ids)
                                         .join(:canonical_documents, id: :canonical_document_id)
                                         .order(:title)
                                         .all

    @favorite_documents_by_group = favorite_documents.group_by(&:group_id)
    favorite_cds_id = favorite_documents.collect(&:canonical_document_id).uniq
    @favorite_canonical_documents = CanonicalDocument.where(id: favorite_cds_id).to_hash(:id)
    @favorite_group_users = User.where(id: @favorite_groups.collect(&:user_id).uniq).to_hash(:id)
  end

  haml :favorites, escape_html: false
end

# Listar todos los favoritos y grupos
get '/user/:user_id/favorites' do |user_id|
  halt_unless_auth('review_view')
  halt 403 unless is_session_user(user_id) or auth_to('user_admin')
  @user = User[user_id]

  # Grupos del usuario
  @favorite_groups = FavoriteGroup.where(user_id: user_id).order(:name)

  # Documentos favoritos en orden alfabético por el título del documento canónico
  favorite_documents = FavoriteDocument.where(user_id: user_id)
                                       .join(:canonical_documents, id: :canonical_document_id)
                                       .order(:title)
  @favorite_documents = favorite_documents.where(activo: true)
  @inactive_favorite_documents = favorite_documents.where(activo: false)
  favorite_cds_id = (@favorite_documents.map(:canonical_document_id) + @inactive_favorite_documents.map(:canonical_document_id)).uniq
  @favorite_canonical_documents = CanonicalDocument.where(id: favorite_cds_id).to_hash(:id)
  @favorite_files_by_cd = IFile.
    join(:file_cds, :file_id=>:id).
    where(:canonical_document_id=>favorite_cds_id).
    where(Sequel.lit("file_cds.not_consider = ? OR file_cds.not_consider IS NULL", 0)).
    select_all(:files).
    select_append(:canonical_document_id).
    all.
    group_by {|file| file[:canonical_document_id]}
  user_reviews=SystematicReview.get_reviews_by_user(user_id).all
  @favorite_reviews_by_cd=favorite_cds_id.each_with_object({}) do |cd_id, memo|
    memo[cd_id]=user_reviews.find_all {|review| review.cd_all_id.include?(cd_id.to_i)}
  end

  haml "users/favorites".to_sym, escape_html: false

end

post '/favorites/user/:user_id/update' do |user_id|
  halt_unless_auth('favorite_edit')
  halt_unless_auth('review_view')
  halt 403 unless is_session_user(user_id)

  user_id=user_id.to_i
  favorites=params['favorites'] || {}
  group_ids=FavoriteGroup.where(user_id: user_id).select_map(:id)

  favorites.each_pair do |cd_id, favorite_params|
    favorite=FavoriteDocument.where(user_id: user_id, canonical_document_id: cd_id).first
    next unless favorite

    group_id=favorite_params['group_id'].to_s
    group_id=group_id.empty? ? nil : group_id.to_i
    group_id=nil unless group_id.nil? || group_ids.include?(group_id)

    favorite.update(
      activo: favorite_params.key?('activo'),
      group_id: group_id,
      commentary: favorite_params['commentary'].to_s
    )
  end

  add_message(t("favorites.updated_successfully"))
  redirect "/user/#{user_id}/favorites"
end


post '/favorite/user/:user_id/canonical_document/:canonical_id/add' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')
  halt_unless_auth('review_view')
  halt 403 unless is_session_user(user_id)
  @user = User[user_id]
  @cd = CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd


  @favorite = FavoriteDocument.where(user_id: user_id, canonical_document_id: cd_id).first
  if @favorite
    @favorite.update(activo: true)
  else
    @favorite = FavoriteDocument.create(user_id: user_id, canonical_document_id: cd_id)
  end

  partial(:favorite, :locals=>{:cd=>@cd, :user_id=>user_id, :favorite_o=>@favorite})
end

post '/favorite/user/:user_id/canonical_document/:canonical_id/remove' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')
  halt 403 unless is_session_user(user_id)

  @user = User[user_id]
  @cd = CanonicalDocument[cd_id]
  FavoriteDocument.where(user_id: user_id, canonical_document_id:cd_id).update(activo: false)
  @favorite=nil

  partial(:favorite, :locals=>{:cd=>@cd, :user_id=>user_id, :favorite_o=>@favorite})
end

post '/favorite/user/:user_id/canonical_document/:canonical_id/file/add' do |user_id, cd_id|
  halt_unless_auth('favorite_edit')
  halt_unless_auth('file_admin')
  halt 403 unless is_session_user(user_id)

  cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if cd.nil?

  favorite=FavoriteDocument.where(user_id: user_id, canonical_document_id: cd_id, activo: true).first
  halt 403 unless favorite

  files_param=params['files']
  files=files_param.is_a?(Array) ? files_param : [files_param]
  files=files.find_all {|file| file && file[:tempfile]}

  if files.any?
    files.each do |file|
      file_proc=FileProcessor.new(file, dir_files)
      if FileExtractionInformation.where(:file_id=>file_proc.file_id).count>0
        add_message(I18n::t("files.file_used_for_extraction_information", filename:file_proc.filename), :error)
      else
        file_proc.add_to_cd(cd)
        add_message(I18n::t("favorites.file_uploaded_for_canonical_document", filename:File.basename(file_proc.filepath), cd_title:cd[:title]))
      end
    end
  else
    add_message(I18n::t(:Files_not_uploaded), :error)
  end
  redirect url("/user/#{user_id}/favorites")
end

post '/favorite/user/:user_id/canonical_document/:canonical_id/restore' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')
  halt 403 unless is_session_user(user_id)

  favorite=FavoriteDocument.where(user_id: user_id, canonical_document_id:cd_id).first
  return 404 unless favorite

  favorite.update(activo: true)
  content_type :json
  JSON.generate(ok:true)
end

post '/favorite/user/:user_id/canonical_document/:canonical_id/destroy' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')
  halt 403 unless is_session_user(user_id)

  favorite=FavoriteDocument.where(user_id: user_id, canonical_document_id:cd_id).first
  return 404 unless favorite && !favorite[:activo]

  favorite.delete
  content_type :json
  JSON.generate(ok:true)
end


put "/favorite/user/:user_id/canonical_document/:cd_id/commentary_favorite" do |user_id, cd_id|
  halt_unless_auth('favorite_edit')
  halt 403 unless is_session_user(user_id)

  @user = User[user_id]
  @cd = CanonicalDocument[cd_id]
  value=params['value'].chomp()
  FavoriteDocument.where(user_id: user_id, canonical_document_id:cd_id).update(commentary:value)
  return 200
end



# @!endgroup

# @!group Grupos de Documentos favoritos
put '/favorite_groups/:gid/edit_field/:field' do |gid, field|
  halt_unless_auth('favorite_edit')

  @fg=FavoriteGroup[gid]
  halt 404 unless @fg
  halt 403 unless is_session_user(@fg[:user_id])

  v=params["value"].chomp
  if @fg and  ["name","description", 'is_public'].include? field
    @fg.update( field.to_sym => v)
  end
  return 200

end
# Crear una nueva categoría (FavoriteGroup)
post '/favorite_groups/new' do
  halt_unless_auth('favorite_edit')

  user_id = session['user_id']
  name=params['name']
  cuenta=FavoriteGroup.where(user_id:user_id, name:name).count
  if name.length>0
    if cuenta>0
      add_message(t("favorites.group_already_created"), :error)
    else
        FavoriteGroup.insert(
          user_id: user_id,
          name: name,
          is_public: params['is_public'] == 'true'
        )
        add_message(t("favorites.group_created"))

    end
  end


  redirect back
end


get '/favorite_group/:fg_id/delete' do |fg_id|
  halt_unless_auth('favorite_edit')
  user_id = session['user_id']
  @fg=FavoriteGroup[fg_id]
  if @fg[:user_id]!=user_id.to_i
    add_error(t("favorites.not_allowed_to_delete"))
  else
    @fg.delete
  end
  add_message(t("favorites.group_deleted"), fg_id:fg_id)
  redirect back
end
# @!endgroup
