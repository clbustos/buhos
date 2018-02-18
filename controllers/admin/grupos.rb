get '/grupos' do 
  error(403) unless permiso('grupos_editar')
  @grupos=Grupo.all
  haml :grupos
end

get "/grupo/:id/edicion" do |id|
  @grupo=Grupo[id]
  @usuarios_id=@grupo.usuarios.map {|v| v.id}
  haml %s{grupos/edicion}
end


get '/grupo/nuevo' do
  error(403) unless permiso('grupos_crear')

  @grupo={:id=>"NA",:description=>"",:administrador_grupo=>nil}
  @usuarios_id=[]
  haml %s{grupos/edicion}
end

get '/grupo/:id/datos.json' do |id|
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
post '/grupo/actualizar' do
  error(403) unless permiso('grupos_editar')

  id=params['grupo_id']
  name=params['name']

  if name.chomp==""
    agregar_mensaje(t(:group_without_name), :error)
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
  redirect url('/grupos')
end

get '/grupo/:grupo_id/delete' do |grupo_id|
  error(403) unless permiso('grupos_editar')
  @grupo=Grupo[grupo_id]
  error(404) unless @grupo
  group_name=@grupo[:name]
  Grupo[grupo_id].delete
  agregar_mensaje(t(:Group_deleted,group_name:group_name))
  redirect back
end