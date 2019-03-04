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
    @users=[]
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
  params['usuario'].each {|id,per|
    if !per['borrar'].nil?
      User[id].delete()
    else
      data=per
      data.delete("password")
      data["active"]=data["active"]?1:0
      User[id].update(data)
    end
  }
  redirect back
end

# @!endgroup