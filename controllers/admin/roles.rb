# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group roles

# List of roles
get '/admin/roles' do
  halt_unless_auth('role_admin')
  @roles=Role
  @authorizations=Authorization.order(:id)
  haml "admin/roles".to_sym, escape_html: false
end


# Form to create a new role

get '/role/new' do
  halt_unless_auth('role_admin')


  role_id="Role #{Digest::SHA1.hexdigest(DateTime.now.to_s)}"
  Role.unrestrict_primary_key

  @role=Role.create({:id=>role_id, :description=>I18n::t('Description')})
  @authorizations=Authorization.order(:id)

  haml "admin/role_edit".to_sym, escape_html: false
end

# Information about a role

get '/role/:id' do |role_id|

  halt_unless_auth('role_view')

  @role=Role[role_id]
  raise Buhos::NoRoleIdError, role_id if @role.nil?
  @authorizations=Authorization.order(:id)
  haml "admin/role_view".to_sym, escape_html: false
end

# Form to update a role

get '/role/:role_id/edit' do |role_id|
  halt_unless_auth('role_admin')

  halt 403, t(:"sinatra_auth.nobody_can_edit_these_roles") if ["administrator","analyst"].include? role_id


  @role=Role[role_id]
  @authorizations=Authorization.order(:id)

  return 404 if @role.nil?
  haml "admin/role_edit".to_sym, escape_html: false
end

# Deletes a role

post '/role/:role_id/delete' do |role_id|
  halt_unless_auth('role_admin')

  error(403) if role_id=="administrator" or role_id=="analyst"
  Role[role_id].delete
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

  if params['authorizations'].nil?
    add_message(t(:role_without_authorizations), :error)
    redirect back
  end
  @role=Role[old_id]
  return 404 if !@role
  exists_another=Role[new_id]
  if old_id==new_id or !exists_another
  $db.transaction(:rollback=>:reraise) do
    AuthorizationsRole.where(:role_id=>old_id).delete
      if (old_id!=new_id)
        Role.unrestrict_primary_key
        Role.where(:id=>old_id).update(:id=>new_id, :description=>params['description'].chomp)
      else
        @role.update(:description=>params['description'].chomp)
      end
      params['authorizations'].each {|authorization_i|
        AuthorizationsRole.insert(:role_id=>new_id,:authorization_id=>authorization_i)
      }
    end
  else
    add_message(t(:Exists_another_role_with_that_name), :error)
  end
  redirect '/admin/roles'
end

# @!endgroup