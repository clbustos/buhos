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