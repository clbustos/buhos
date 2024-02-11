# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

#@!group groups routes

# Display list of groups
get '/admin/groups' do
  halt_unless_auth('group_admin')
  @groups=Group.all
  haml :groups, escape_html: false
end

# Display form to edit a group

get "/group/:id/edit" do |id|
  halt_unless_auth('group_admin')
  @group=Group[id]
  @users_id=@group.users.map {|v| v.id}
  haml "groups/edit".to_sym, escape_html: false
end

# Display form to create a new group

get '/group/new' do
  halt_unless_auth('group_admin')
  Group_I = Struct.new(:id, :name, :description, :group_administrator)
  @group   = Group_I.new('NA',
                         params['name'],
                         params['description'],
                         params['admin_id']
  )
  @users_id=[]
  if params['users']
    @users_id=params['users'].map {|v| v.to_i}
  end
  haml "groups/edit".to_sym, escape_html: false
end

# Display information for a group
get "/group/:id" do |id|
  halt_unless_auth('group_view')
  @group=Group[id]
  @users_id=@group.users.map {|v| v.id}
  haml "groups/view".to_sym, escape_html: false
end


# Returns a json with information for a group

get '/group/:id/datos.json' do |id|
  halt_unless_auth('group_view')

  require 'json'
  @group=Group[id]
  content_type :json
  {:id=>id,
  :name=>@group.name,
  :group_administrator=>@group.group_administrator,
   :description=>@group.description,
   :users=>@group.users_dataset.order(:name).map {|u| {id:u[:id], name:u[:name]}}
  }.to_json
end

# Updates information for a group
# @see #group/:id/edit
post '/group/update' do
  halt_unless_auth('group_admin')

  id=params['group_id']
  name=params['name']
  error=false
  if name.chomp==""
    add_message(t(:group_without_name), :error)
    error=true
  end
  description=params['description']
  if description.chomp==""
    add_message(t(:group_without_description), :error)
    error=true
  end

  admin_id=params['group_administrator']
  users=params['users'] ? params['users'].keys : []
  if users.length==0
    add_message(t(:group_without_users), :error)
    error=true
  end


  if not users.include? admin_id
    add_message(t(:group_should_include_admin_as_user), :error)
    error=true
  end

  if error
    if id=="NA"
      new_params={
        name:name,
        description:description,
        admin_id:admin_id,
        "users[]"=>users
      }
      uri = URI.parse(url("group/new"))
      uri.query=URI.encode_www_form(new_params)
      redirect to(uri)
    else
      redirect back
    end
  end

  if id=="NA"
    group=Group.create(:name=>name,:description=>description, :group_administrator=>admin_id)
    id=group.id
  else
    Group[id].update(:name=>name,:description=>description, :group_administrator=>admin_id)
  end
  GroupsUser.where(:group_id=>id).delete()
  users.each {|u|
    GroupsUser.insert(:user_id=>u, :group_id=>id)
  }
  redirect url('/admin/groups')
end

# Deletes a group
# @todo modify to use POST or DELETE method

get '/group/:group_id/delete' do |group_id|
  halt_unless_auth('group_admin')
  @group=Group[group_id]
  error(404) unless @group
  group_name=@group[:name]
  Group[group_id].delete
  add_message(t(:Group_deleted, group_name:group_name))
  redirect back
end

#@!endgroup