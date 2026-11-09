get '/admin/configurations' do
  halt_unless_auth('role_admin')
  @configurations = Buhos::Configuration.order(:id)
  haml :'admin/configurations', escape_html: false
end

post '/admin/configurations/update' do
  halt_unless_auth('role_admin')
  key = params['key']
  halt 400, t(:Configuration_invalid_key) unless key.is_a?(String) && !key.strip.empty? && key.length <= 255
  halt 400 unless params['value'].is_a?(String)

  Buhos::Configuration.set(key, params['value'])
  add_message(t(:Configuration_saved))
  redirect url('/admin/configurations')
end
