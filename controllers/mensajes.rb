post '/mensaje_rs/:ms_id/visto_por/:user_id' do |ms_id, usuario_id|
  ms=Mensaje_Rs_Visto.where(:m_rs_id=>ms_id, :usuario_id=>usuario_id)
  unless ms.empty?
    ms.update(:visto=>true)
  else
    Mensaje_Rs_Visto.insert(:m_rs_id=>ms_id, :usuario_id=>usuario_id,:visto=>true)
  end
  return 200
end

post '/mensaje/:m_id/visto_por/:user_id' do |m_id, usuario_id|
  ms=Mensaje.where(:id=>m_id, :usuario_hacia=>usuario_id)
  if ms
    ms.update(:visto=>true)
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
    agregar_mensaje(t("messages.add_reply_to", subject: ms.asunto))
  end
  redirect back

end


post '/message_per/:m_id/reply' do |m_id|
  m_per=Mensaje[m_id]
  @usuario_id=params['user_id']
  return 404 if m_per.nil? or  @usuario_id.nil?
  @asunto=params['asunto'].chomp
  @texto=params['texto'].chomp
  $db.transaction(:rollback=>:reraise) do
    id=Mensaje.insert(:usuario_desde=>@usuario_id, :usuario_hacia=>m_per.usuario_desde , :respuesta_a=>m_per.id, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto)
    agregar_mensaje(t("messages.add_reply_to", subject: m_per.asunto))
  end
  redirect back

end

