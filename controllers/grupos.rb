get '/grupos' do 
  error(403) unless permiso('editar_grupos')
  @grupos=Grupo.all
  haml :grupos
end

get "/grupo/:id/edicion" do |id|
  @grupo=Grupo[id]
  @usuarios_id=@grupo.usuarios.map {|v| v.id}
  haml %s{grupos/edicion}
end
get '/grupo/nuevo' do
  @grupo={:id=>"NA",:description=>"",:administrador_grupo=>nil}
  @usuarios_id=[]
  haml %s{grupos/edicion}
end


post '/grupo/actualizar' do
  id=params['grupo_id']
  name=params['name']
  description=params['description']

  administrador=params['administrador_grupo']
  usuarios=params['usuarios'].keys
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