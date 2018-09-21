# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group User


# View and edit user attributes
get '/user/:user_id' do |user_id|
  if user_id=='new'
    halt_unless_auth('user_admin')
    new_user_id=User.create_new_user(session['language'])
    @usuario=User[new_user_id]
  else
    @usuario=User[user_id]
  end

  raise Buhos::NoUserIdError, user_id if !@usuario

  # Debo reemplazar por las elecciones de acuerdo a equipo

  @have_permit = auth_to("user_admin") or is_session_user(@usuario.id)

  @rss=@usuario.systematic_reviews.where(:active=>true)

  @select_role=get_xeditable_select(Role.inject({}) {|ac,v| ac[v[:id]]=v[:id];ac},'/user/edit/rol_id','select_role')
  @select_role.active=false if(!auth_to("user_admin") or user_id.to_i==session['user_id'])

  @select_active_user=get_xeditable_select_bool('/user/edit/activa','select_active')
  @select_active_user.active=false if(!auth_to("user_admin") or user_id.to_i==session['user_id'])

  @select_language=get_xeditable_select(available_locales_hash, '/user/edit/language','select_language')
  @select_language.active=false if(!auth_to("user_admin") and user_id.to_i!=session['user_id'])

  haml :user
end

# An alias to /user/:user_id
get '/user/:user_id/edit' do |user_id|
  halt 403 unless (auth_to('user_admin') or is_session_user(user_id))
  redirect "/user/#{user_id}"
end

# Edit an attribute of a user
put '/user/edit/:field' do |field|
  halt_unless_auth('user_admin')
  put_editable(request) {|id,value|
    user=User[id]
    raise Buhos::NoUserIdError, id if !user
    if field=='login'
      halt 405, t(:Login_already_used) if User.where(:login=>value).exclude(:id=>id).count>0
      halt 405, t(:Login_cant_be_nil) if value.chomp==""
    end
    user.update(field.to_sym=>value)
  }
end


# Form to change password
get '/user/:user_id/change_password' do |user_id|

  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  return 403 unless (is_session_user(user_id) or auth_to("user_admin"))

  haml "users/change_password".to_sym
end


# Change the password of a user
post '/user/:user_id/change_password' do |user_id|
  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user


  return 403 unless (is_session_user(user_id) or auth_to("user_admin"))

  password_1=params['password']
  password_2=params['repeat_password']
  if password_1!=password_2
    add_message(I18n::t("password.not_equal_password"), :error)
    redirect back
  else
    @user.change_password(password_1)
    add_message(I18n::t("password.password_updated"))
    redirect "/user/#{@user[:id]}".to_sym
  end
end

# See all messages for a user
# Alias for {'/user/:user_id/messages'}
get '/my_messages' do
  redirect "/user/#{session['user_id']}/messages"
end


# @!group Personal messages




# Get all user messages
get '/user/:user_id/messages' do |user_id|
  @user=User[user_id]


  halt 403 unless (is_session_user(user_id) or auth_to("message_view"))

  raise Buhos::NoUserIdError, user_id if !@user

  @messages_personal=Message.where(:user_to=>user_id).order(Sequel.desc(:time))

  @messages_personal_sent=Message.where(:user_from=>user_id).order(Sequel.desc(:time))


  @n_not_readed=@messages_personal.where(:viewed=>false).count
  @srs=@user.systematic_reviews

  haml "users/messages".to_sym
end

# Compose a personal message
get '/user/:user_id/compose_message' do |user_id|
  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  return 403 unless (auth_to('message_edit') and is_session_user(user_id))

  @ms_id="NEW"
  @ms_text=""

  haml "users/compose_message".to_sym
end

# Send a personal message
post '/user/:user_id/compose_message/send' do |user_id|

  return 403 unless (auth_to('message_edit') and is_session_user(user_id))

  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  subject=params['subject'].chomp
  text=params['text'].chomp
  destination=params['to']
  @user_to=User[destination]
  if @user_to
    Message.insert(:user_from=>user_id, :user_to=>destination, :reply_to=>nil, :time=>DateTime.now(), :subject=>subject, :text=>text, :viewed=>false)
    add_message(t("messages.new_message_for_user", user_name:@user_to[:name]))

  else
    add_message(t(:User_not_exists, user_id:destination), :error)
  end
  redirect "/user/#{user_id}/messages"

end

# @!endgroup
