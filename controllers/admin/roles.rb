get '/admin/roles' do
  @roles=Rol
  @permisos=Permiso.order(:id)
  haml "admin/roles".to_sym
end

post '/admin/roles/update' do
  error(403) unless permiso('editar_roles')
  roles=params['permisos']
  roles.each {|rol_i, permisos|
    PermisosRol.where(:rol_id=>rol_i).delete
      permisos.each {|permiso_i|
        PermisosRol.insert(:rol_id=>rol_i,:permiso_id=>permiso_i)
      }
  }
  redirect back
end




get '/role/new' do
  error(403) unless permiso('roles_crear')
  role_id="Role #{Digest::SHA1.hexdigest(DateTime.now.to_s)}"
  Rol.insert(:id=>role_id, :descripcion=>"Por completar")
  redirect "role/#{role_id}/edit"
end


get '/role/:role_id/edit' do |role_id|
  @role=Rol[role_id]
  @permisos=Permiso.order(:id)

  return 404 if @role.nil?
  haml "admin/role_edit".to_sym
end

get '/role/:role_id/delete' do |role_id|
  error(403) unless permiso('editar_roles')
  error(403) if role_id=="administrator" or role_id=="analyst"
  Rol[role_id].delete
  agregar_mensaje(t(:Role_deleted_name, role:role_id))
  redirect back
end

post '/role/update' do
  old_id=params['role_id_old']
  new_id=params['role_id_new']

  if new_id.chomp==""
    agregar_mensaje(t(:role_without_name), :error)
    redirect back
  end

  @role=Rol[old_id]
  return 404 if !@role
  exists_another=Rol[new_id]
  if !exists_another

  $db.transaction(:rollback=>:reraise) do
    PermisosRol.where(:rol_id=>old_id).delete


      if (old_id!=new_id)
        Rol.unrestrict_primary_key
        Rol.where(:id=>old_id).update(:id=>new_id, :descripcion=>params['description'].chomp)
      else
        @role.update(:descripcion=>params['description'].chomp)
      end
      params['permits'].each {|permiso_i|
        PermisosRol.insert(:rol_id=>new_id,:permiso_id=>permiso_i)
      }
    end
  else
    agregar_mensaje(t(:Exists_another_role_with_that_name), :error)
  end
  redirect '/admin/roles'
end