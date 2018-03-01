get '/admin/users/?' do
  halt_unless_auth('user_admin')
  @usr_bus=params[:usuarios_busqueda]
  if(@usr_bus.nil? or @usr_bus=="")
    @usuarios=[]
  else
    @usuarios=Usuario.filter(Sequel.like(:nombre, "%#{@usr_bus}%")).order(:nombre)
  end
  #log.info(@personas.all)  
  @roles=Rol.order()
  haml :users
end


post '/admin/users/update' do
  halt_unless_auth('user_admin')
  params['usuario'].each {|id,per|
    if(id=='N')
      if(per["nombre"]!="")
        data=per
        data["password"]=Digest::SHA1.hexdigest(per["password"])
        data["activa"]=data["activa"]?1:0
        log.info(data)
        Usuario.insert(data)
      end
    elsif !per['borrar'].nil?
      Usuario[id].delete()
    else
      data=per
      if per["password"]==""
        data.delete("password")
      else
        data["password"]=Digest::SHA1.hexdigest(per["password"])
      end
      data["activa"]=data["activa"]?1:0
      Usuario[id].update(data)
    end
  }
  redirect back
end
