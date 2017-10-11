post '/mensaje_rs/:ms_id/visto_por/:user_id' do |ms_id, usuario_id|
  ms=Mensaje_Rs_Visto.where(:m_rs_id=>ms_id, :usuario_id=>usuario_id)
  if ms
    ms.update(:visto=>true)
  else
    Mensaje_Rs_Visto.insert(:m_rs_id=>ms_id, :usuario_id=>usuario_id,:visto=>true)
  end
  return 200
end