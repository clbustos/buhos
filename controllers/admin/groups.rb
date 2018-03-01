get '/admin/groups' do
  halt_unless_auth('group_admin')
  @grupos=Grupo.all
  haml :groups
end


get "/group/:id/edit" do |id|
  halt_unless_auth('group_admin')
  @grupo=Grupo[id]
  @usuarios_id=@grupo.usuarios.map {|v| v.id}
  haml %s{groups/edit}
end


get '/group/new' do
  halt_unless_auth('group_admin')
  @grupo={:id=>"NA",:description=>"",:administrador_grupo=>nil}
  @usuarios_id=[]
  haml %s{groups/edit}
end
get "/group/:id" do |id|
  halt_unless_auth('group_view')
  @grupo=Grupo[id]
  @usuarios_id=@grupo.usuarios.map {|v| v.id}
  haml %s{groups/view}
end



get '/group/:id/datos.json' do |id|
  halt_unless_auth('group_view')

  require 'json'
  @grupo=Grupo[id]
  content_type :json
  {:id=>id,
  :name=>@grupo.name,
  :group_administrator=>@grupo.administrador_grupo,
   :description=>@grupo.description,
   :users=>@grupo.usuarios_dataset.order(:nombre).map {|u| {id:u[:id], name:u[:nombre]}}
  }.to_json
end
post '/group/update' do
  halt_unless_auth('group_admin')

  id=params['grupo_id']
  name=params['name']

  if name.chomp==""
    add_message(t(:group_without_name), :error)
    redirect back
  end
  description=params['description']

  administrador=params['administrador_grupo']
  usuarios=params['usuarios'] ? params['usuarios'].keys : []
  if id=="NA"
    grupo=Grupo.create(:name=>name,:description=>description, :administrador_grupo=>administrador)
    id=grupo.id
  else
    Grupo[id].update(:name=>name,:description=>description, :administrador_grupo=>administrador)
  end
  Grupo_Usuario.where(:grupo_id=>id).delete()
  usuarios.each {|u|
    Grupo_Usuario.insert(:usuario_id=>u, :grupo_id=>id)
  }
  redirect url('/admin/groups')
end

get '/group/:grupo_id/delete' do |grupo_id|
  halt_unless_auth('group_admin')
  @grupo=Grupo[grupo_id]
  error(404) unless @grupo
  group_name=@grupo[:name]
  Grupo[grupo_id].delete
  add_message(t(:Group_deleted, group_name:group_name))
  redirect back
end