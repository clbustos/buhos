get '/usuario/:user_id' do |user_id|
  @usuario=Usuario[user_id]
  # Debo reemplazar por las elecciones de acuerdo a equipo
  @rss=@usuario.revisiones_sistematicas.where(:activa=>true)



  @select_role=get_xeditable_select(Rol.inject({}) {|ac,v| ac[v[:id]]=t("role.#{v[:id]}");ac},'/user/edit/rol_id','select_role')
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
  @messages_personal=Mensaje.where(:usuario_hacia=>user_id).order(Sequel.desc(:tiempo))
  @n_not_readed=@messages_personal.where(:visto=>false).count
  @srs=@user.revisiones_sistematicas
  @messages_sr_checked=Mensaje_Rs_Visto.where(:usuario_id=>user_id).as_hash(:m_rs_id)
  haml "users/messages".to_sym
end

get '/user/:user_id/compose_message' do |user_id|
  @user=Usuario[user_id]
  @ms_id="NEW"
  @ms_text=""
  return 403 unless user_id.to_s==session['user_id'].to_s
  haml "users/compose_message".to_sym
end