get '/administrador' do 
  @usuario=Usuario[session['user_id']]
  #$log.info(session)
  haml :index
end

get '/analista' do 
  @usuario=Usuario[session['user_id']]
  @elecciones=Eleccion.where(:activa=>1)

  haml :control
end

get '/digitador' do 
  @usuario=Usuario[session['user_id']]
  haml :index
end

get '/visualizador' do
  redirect url("/resultados")
end

get '/usuario/:user_id' do |user_id|
  @usuario=Usuario[user_id]
  # Debo reemplazar por las elecciones de acuerdo a equipo
  @elecciones=@usuario.elecciones_por_equipo(user_id)
  @subelecciones=Subeleccion.where(:eleccion_id=>@elecciones.map[:id])
  haml @usuario.rol_id.to_sym
end
