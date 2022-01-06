# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

#@!group groups routes

# Display list of groups
get '/admin/groups' do
  halt_unless_auth('group_admin')
  @groups=Group.all
  haml :groups
end

# Display form to edit a group

get "/group/:id/edit" do |id|
  halt_unless_auth('group_admin')
  @group=Group[id]
  @users_id=@group.users.map {|v| v.id}
  haml %s{groups/edit}
end

# Display form to create a new group

get '/group/new' do
  halt_unless_auth('group_admin')
  @group={:id=>"NA",:description=>"",:group_administrator=>nil}
  @users_id=[]
  haml %s{groups/edit}
end

# Display information for a group
get "/group/:id" do |id|
  halt_unless_auth('group_view')
  @group=Group[id]
  @users_id=@group.users.map {|v| v.id}
  haml %s{groups/view}
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

  if name.chomp==""
    add_message(t(:group_without_name), :error)
    redirect back
  end
  description=params['description']

  administrador=params['group_administrator']
  users=params['users'] ? params['users'].keys : []
  if id=="NA"
    group=Group.create(:name=>name,:description=>description, :group_administrator=>administrador)
    id=group.id
  else
    Group[id].update(:name=>name,:description=>description, :group_administrator=>administrador)
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