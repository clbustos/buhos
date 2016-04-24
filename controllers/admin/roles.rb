get '/admin/roles' do
  @roles=Rol
  @permisos=Permiso.order(:id)
  haml "admin/roles".to_sym
end

post '/admin/roles/actualizar' do
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
