# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2021, Claudio Bustos Navarrete
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

  @have_permit_password = auth_to("user_admin")

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
    if @users_id.map(&:to_i).include? session['user_id']
      add_message(::I18n.t("users_admin.cant_delete_itself"))
      redirect back
    else
      return haml "users/delete_confirm".to_sym
    end
  elsif params['action']=='edit'
    @users_id=users
    @users=User.where(:id=>@users_id)
    return haml "users/multiple_edit".to_sym
  end
  redirect back
end


post '/admin/users/delete' do
  if params['action']=='delete'
    users=User.where(:id=>params['users'].split(","))

    if !users
      add_message(::I18n.t("users_admin.no_valid_user_selected"), :error)
    else
      $db.transaction do
        User.where(:id=>params['users'].split(",")).delete
      end
      add_message(::I18n.t("users_admin.action_delete", ids: params['users']))
    end
  end
  redirect url('admin/users')
end

post '/admin/users/update_edit' do
  user_info=params['user']
  if !user_info
    add_message(::I18n.t("users_admin.no_valid_user_selected"), :error)
    redirect url("admin/users")
  else
    result=Result.new
    user_info.each do |user_id, user_info|
      begin
        if user_info[:name].strip==""
          result.error(::I18n.t("users_admin.user_should_have_a_name", id: user_id))
        elsif user_info[:login].strip==""
          result.error(::I18n.t("users_admin.user_should_have_a_login", id: user_id))
        else
          $db.transaction do
            User[user_id].update(name:user_info[:name],
                                 login:user_info[:login],
                                 active: user_info[:active].to_i==1,
                                 role_id: user_info[:role_id],
                                 language: user_info[:language])
            result.success(::I18n.t("users_admin.update_was_successful", id: user_id))
            end
        end

        rescue Exception => e
          result.error(::I18n.t("users_admin.update_failed", id: user_id, message:e.message))
        end
    end
    add_result(result)
  end
  if result.success?
    redirect url("admin/users")
  else
    @users_id=user_info.keys
    @users=User.where(:id=>@users_id)
    return haml "users/multiple_edit".to_sym
  end
end

# @!endgroup