post '/message_sr/:ms_id/seen_by/:user_id' do |ms_id, usuario_id|
  halt_unless_auth('message_edit')

  ms=Mensaje_Rs_Visto.where(:m_rs_id=>ms_id, :usuario_id=>usuario_id)


  unless ms.empty?
    ms.update(:visto=>true)
  else
    Mensaje_Rs_Visto.insert(:m_rs_id=>ms_id, :usuario_id=>usuario_id,:visto=>true)
  end
  return 200
end

post '/message/:m_id/seen_by/:user_id' do |m_id, usuario_id|
  halt_unless_auth('message_edit')
  ms=Mensaje.where(:id=>m_id, :usuario_hacia=>usuario_id)
  if ms
    ms.update(:visto=>true)
  end
  return 200
end



post '/message_sr/:ms_id/reply' do |ms_id|
  halt_unless_auth('message_edit')
  ms=Mensaje_Rs[ms_id]
  @usuario_id=params['user_id']
  raise Buhos::NoUserIdError, params['user_id'] unless Usuario[@usuario_id]
  halt 403 unless is_session_user(@usuario_id)

  return 404 if ms.nil?
  @asunto=params['asunto']
  @texto=params['texto']
  $db.transaction(:rollback=>:reraise) do
    Mensaje_Rs.insert(:revision_sistematica_id=>ms.revision_sistematica_id, :usuario_desde=>@usuario_id, :respuesta_a=>ms.id, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto)
    agregar_mensaje(t("messages.add_reply_to", subject: ms.asunto))
  end
  redirect back

end


post '/message_per/:m_id/reply' do |m_id|
  halt_unless_auth('message_edit')
  m_per=Mensaje[m_id]
  @usuario_id=params['user_id']
  @user=Usuario[@usuario_id]


  raise Buhos::NoUserIdError, @usuario_id if !@user
  raise Buhos::NoMessageIdError, m_id     if !m_per

  halt 403 unless is_session_user(@usuario_id)


  @asunto=params['asunto'].chomp
  @texto=params['texto'].chomp
  $db.transaction(:rollback=>:reraise) do
    id=Mensaje.insert(:usuario_desde=>@usuario_id, :usuario_hacia=>m_per.usuario_desde , :respuesta_a=>m_per.id, :tiempo=>DateTime.now(), :asunto=>@asunto, :texto=>@texto, :visto=>false)
    agregar_mensaje(t("messages.add_reply_to", subject: m_per.asunto))
  end
  redirect back

end

