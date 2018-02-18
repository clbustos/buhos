get '/usuario/:user_id' do |user_id|
  @usuario=Usuario[user_id]
  # Debo reemplazar por las elecciones de acuerdo a equipo
  @rss=@usuario.revisiones_sistematicas.where(:activa=>true)



  @select_role=get_xeditable_select(Rol.inject({}) {|ac,v| ac[v[:id]]=v[:id];ac},'/user/edit/rol_id','select_role')
  @select_role.active=false if(!permiso("editar_usuarios") or user_id.to_i==session['user_id'])

  @select_active_user=get_xeditable_select_bool('/user/edit/activa','select_active')
  @select_active_user.active=false if(!permiso("editar_usuarios") or user_id.to_i==session['user_id'])

  @select_language=get_xeditable_select(available_locales_hash, '/user/edit/language','select_language')
  @select_language.active=false if(!permiso("editar_usuarios") and user_id.to_i!=session['user_id'])

  haml :usuario
end


put '/user/edit/:field' do |field|
  put_editable(request) {|id,value|
    user=Usuario[id]
    return 404 if !user
    if field=='login'
      return 505 if Usuario.where(:login=>value).exclude(:id=>id).count>0
    end
    user.update(field.to_sym=>value)
  }
end


get '/user/:user_id/messages' do |user_id|
  @user=Usuario[user_id]

  return 403 unless user_id.to_s==session['user_id'].to_s
  @messages_personal=Mensaje.where(:usuario_hacia=>user_id, :respuesta_a=>nil).order(Sequel.desc(:tiempo))
  @n_not_readed=@messages_personal.where(:visto=>false).count
  @srs=@user.revisiones_sistematicas

  haml "users/messages".to_sym
end

get '/user/:user_id/compose_message' do |user_id|
  @user=Usuario[user_id]
  @ms_id="NEW"
  @ms_text=""
  return 403 unless user_id.to_s==session['user_id'].to_s
  haml "users/compose_message".to_sym
end

post '/user/:user_id/compose_message/send' do |user_id|
  @user=Usuario[user_id]
  return 403 unless user_id.to_s==session['user_id'].to_s
  asunto=params['asunto'].chomp
  texto=params['texto'].chomp
  destination=params['to']
  @user_to=Usuario[destination]
  if @user_to
    Mensaje.insert(:usuario_desde=>user_id, :usuario_hacia=>destination, :respuesta_a=>nil, :tiempo=>DateTime.now(), :asunto=>asunto, :texto=>texto, :visto=>false)
    agregar_mensaje(t("messages.new_message_for_user", user_name:@user_to[:nombre]))

  else
    agregar_mensaje(t(:User_not_exists, user_id:destination), :error)
  end
  redirect "/user/#{user_id}/messages"

end


get '/user/new' do
  return 403 unless permiso('usuarios_crear')
  ultimo_usuario=$db["SELECT max(id) as max_id from usuarios"].get(:max_id).to_i
  n_id=ultimo_usuario+1
  usuario_nuevo_id=Usuario.insert(:login=>"user_#{n_id}", :nombre=>t(:User_only_name, :user_name=>n_id), :password=>Digest::SHA256.hexdigest("user_#{n_id}") , :rol_id=>'analyst', :activa=>true,:language=>session['language'])
  redirect "/usuario/#{usuario_nuevo_id}".to_sym
end


get '/user/:user_id/change_password' do |user_id|
  @user=Usuario[user_id]
  return 403 unless session['user_id']==@user.id or permiso("editar_usuarios")

  haml "users/change_password".to_sym
end

post '/user/:user_id/change_password' do |user_id|
  @user=Usuario[user_id]
  return 403 unless session['user_id']==@user.id or permiso("editar_usuarios")

  password_1=params['password']
  password_2=params['repeat_password']
  if password_1!=password_2
    agregar_mensaje(I18n::t("password.not_equal_password"), :error)
    redirect back
  else
    @user.change_password(password_1)
    agregar_mensaje(I18n::t("password.password_updated"))
    redirect "/usuario/#{@user[:id]}".to_sym
  end
end