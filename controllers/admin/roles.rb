get '/admin/roles' do
  halt_unless_auth('role_admin')
  @roles=Rol
  @permisos=Permiso.order(:id)
  haml "admin/roles".to_sym
end


get '/role/new' do
  halt_unless_auth('role_admin')


  role_id="Role #{Digest::SHA1.hexdigest(DateTime.now.to_s)}"
  Rol.unrestrict_primary_key

  @role=Rol.create({:id=>role_id, :descripcion=>I18n::t('Description')})
  @permisos=Permiso.order(:id)

  haml "admin/role_edit".to_sym
end


get '/role/:id' do |role_id|

  halt_unless_auth('role_view')

  @role=Rol[role_id]
  raise Buhos::NoRoleIdError, role_id if @role.nil?
  @permisos=Permiso.order(:id)
  haml "admin/role_view".to_sym
end









get '/role/:role_id/edit' do |role_id|
  halt_unless_auth('role_admin')

  halt 403, t(:"sinatra_auth.nobody_can_edit_these_roles") if ["administrator","analyst"].include? role_id


  @role=Rol[role_id]
  @permisos=Permiso.order(:id)

  return 404 if @role.nil?
  haml "admin/role_edit".to_sym
end

get '/role/:role_id/delete' do |role_id|
  halt_unless_auth('role_admin')

  error(403) if role_id=="administrator" or role_id=="analyst"
  Rol[role_id].delete
  add_message(t(:Role_deleted_name, role:role_id))
  redirect back
end

post '/role/update' do
  halt_unless_auth('role_admin')

  old_id=params['role_id_old']
  new_id=params['role_id_new']

  if new_id.chomp==""
    add_message(t(:role_without_name), :error)
    redirect back
  end

  @role=Rol[old_id]
  return 404 if !@role
  exists_another=Rol[new_id]
  if old_id==new_id or !exists_another
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
    add_message(t(:Exists_another_role_with_that_name), :error)
  end
  redirect '/admin/roles'
end