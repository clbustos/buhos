# @!group Documentos favoritos

# Listar todos los favoritos y grupos
get '/user/:user_id/favorites' do |user_id|
  halt_unless_auth('review_view')
  @user = User[user_id]

  # Grupos del usuario
  @favorite_groups = FavoriteGroup.where(user_id: user_id).order(:name)

  # Documentos favoritos en orden alfabético por el título del documento canónico
  @favorite_documents = FavoriteDocument.where(user_id: user_id)
                                        .join(:canonical_documents, id: :canonical_document_id)
                                        .order(:title)

  haml "users/favorites".to_sym, escape_html: false

end


post '/favorite/user/:user_id/canonical_document/:canonical_id/add' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')
  halt_unless_auth('review_view')
  @user = User[user_id]
  @cd = CanonicalDocument[cd_id]
  raise Buhos::NoCanonicalDocument, id if !@cd


  @favorite = FavoriteDocument.find_or_create(user_id: user_id, canonical_document_id: cd_id)

  partial(:favorite, :locals=>{:cd=>@cd, :user_id=>user_id, :favorite_o=>@favorite})
end

post '/favorite/user/:user_id/canonical_document/:canonical_id/remove' do |user_id, cd_id |
  halt_unless_auth('favorite_edit')

  @user = User[user_id]
  @cd = CanonicalDocument[cd_id]
  FavoriteDocument.where(user_id: user_id, canonical_document_id:cd_id).delete
  @favorite=nil
  partial(:favorite, :locals=>{:cd=>@cd, :user_id=>user_id, :favorite_o=>@favorite})
end


put "/favorite/user/:user_id/canonical_document/:cd_id/commentary_favorite" do |user_id, cd_id|
  halt_unless_auth('favorite_edit')

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
  # TODO: Que solo lo pueda modificar un administrador o el usuario dueño

  v=params["value"].chomp
  if @fg and  ["name","description"].include? field
    @fg.update( field.to_sym => v)
  end
  return 200

end
# Crear una nueva categoría (FavoriteGroup)
post '/favorite_groups/new' do
  halt_unless_auth('favorite_edit')

  user_id = session['user_id']
  name=params['name']
  cuenta=FavoriteGroup.where(name:name).count
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
  if @fg[:user_id]!=user_id
    add_error(t("favorites.not_allowed_to_delete"))
  else
    @fg.delete
  end
  add_message(t("favorites.group_deleted"), fg_id:fg_id)
  redirect back
end
# @!endgroup