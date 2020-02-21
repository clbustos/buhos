# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group users

# Get list of users
get '/admin/users/?' do
  halt_unless_auth('user_admin')
  @usr_bus=params[:users_search]
  if(@usr_bus.nil? or @usr_bus=="")
    @users=User.all
  else
    @users=User.filter(Sequel.ilike(:name, "%#{@usr_bus}%")).order(:name)
  end
  #log.info(@personas.all)
  @roles=Role.order()
  haml :users
end

# Update information for users
post '/admin/users/update' do
  halt_unless_auth('user_admin')
  if params['user'].nil?
    add_message(::I18n.t(:No_users_selected), :error)
    redirect back
  end
  users=params['user']
  if params['action']=='inactive'
    User.where(:id => users).update(:active=>false)
    add_message(::I18n.t("users_admin.action_inactive", ids: users.join(",")))
  elsif params['action']=='active'
    User.where(:id => users).update(:active=>true)
    add_message(::I18n.t("users_admin.action_active", ids: users.join(",")))
  elsif params['action']=='delete'
    @users_id=users
    @users=User.where(:id=>@users_id)
    return haml "users/delete_confirm".to_sym
  end
  redirect back
end


post '/admin/users/delete' do
  if params['action']=='delete'
    users=User.where(:id=>params['users'].split(","))
    if !users
      add_message(t(::I18n.t("users_admin.no_valid_user_selected"), :error))
    else
      $db.transaction do
        User.where(:id=>params['users'].split(",")).delete
      end
      add_message(::I18n.t("users_admin.action_delete", ids: params['users']))
    end
  end
  redirect url('admin/users')
end
# @!endgroup