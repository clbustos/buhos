


get '/admin/routes' do
  halt_unless_auth('reflection')
  lines = Buhos::Reflection.get_routes(self)
    "<html><body>#{lines.sort.join('<br/>')}</body></html>"

end


get '/admin/authorizations' do
  halt_unless_auth('reflection')
  auth=Buhos::Reflection.get_authorizations(self)
  @files=auth.files
  @permits=auth.permits
  haml "admin/permits".to_sym

end