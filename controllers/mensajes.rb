post '/mensaje_rs/:ms_id/visto_por/:user_id' do |ms_id, usuario_id|
  ms=Mensaje_Rs_Visto.where(:m_rs_id=>ms_id, :usuario_id=>usuario_id)
  unless ms.empty?
    ms.update(:visto=>true)
  else
    Mensaje_Rs_Visto.insert(:m_rs_id=>ms_id, :usuario_id=>usuario_id,:visto=>true)
  end
  return 200
end

post '/mensaje_rs/:ms_id/respuesta' do |ms_id|
  ms=Mensaje_Rs[ms_id]

  @usuario_id=params['user_id']
  return 404 if ms.nil? or  @usuario_id.nil?
  @asunto=params['asunto']
  @texto=params['texto']
  $db.transaction(:rollback=>:reraise) do
    id=Mensaje_Rs.insert(:revision_sistematica_id=>ms.revision_sistematica_id, :usuario_desde=>@usuario_id, :respuesta_a=>ms.id, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto)
    agregar_mensaje("Agregada respuesta #{id} a mensaje #{ms.id}")
  end
  redirect back

end

