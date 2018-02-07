get '/decision/revision/:revision_id/usuario/:usuario_id/canonico_documento/:cd_id/etapa/:etapa' do |revision_id, usuario_id, cd_id, etapa|
  revision=Revision_Sistematica[revision_id]
  cd=Canonico_Documento[cd_id]
  ars=AnalisisRevisionSistematica.new(revision)
  usuario=Usuario[usuario_id]
  decisiones=Decision.where(:usuario_id => usuario_id, :revision_sistematica_id => revision_id,
                            :etapa => etapa).as_hash(:canonico_documento_id)
  if !revision or !cd or !usuario
    return [500, "No existe alguno de los componentes"]
  end
  return partial(:decision, :locals => {revision: revision, cd: cd, decisiones: decisiones, ars: ars, usuario_id: usuario_id, etapa: etapa})
end


put '/decision/revision/:revision_id/usuario/:usuario_id/canonico_documento/:cd_id/etapa/:etapa/comentario' do |revision_id, usuario_id, cd_id, etapa|
  pk = params['pk']
  value = params['value']
  $db.transaction(:rollback => :reraise) do
    des=Decision.where(:revision_sistematica_id => revision_id, :usuario_id => usuario_id, :canonico_documento_id => pk, :etapa => etapa).first
    if des
      des.update(:comentario => value)
    else
      Decision.insert(:revision_sistematica_id => revision_id,
                      :decision => nil,
                      :usuario_id => usuario_id, :canonico_documento_id => pk, :etapa => etapa, :comentario => value.strip)
    end
  end
  return 200
end


post '/decision/revision/:revision_id/usuario/:usuario_id/canonico_documento/:cd_id/etapa/:etapa/decision' do |revision_id, usuario_id, cd_id, etapa|

  #cd_id=params['pk_id']
  decision=params['decision']
  #usuario_id=params['user_id']
  only_buttons = params['only_buttons'] == "1"

  $db.transaction do
    des=Decision.where(:revision_sistematica_id => revision_id, :usuario_id => usuario_id, :canonico_documento_id => cd_id, :etapa => etapa).first
    if des
      des.update(:decision => decision)
    else
      Decision.insert(:revision_sistematica_id => revision_id,
                      :decision => decision,
                      :usuario_id => usuario_id, :canonico_documento_id => cd_id, :etapa => etapa)
    end
  end
  revision=Revision_Sistematica[revision_id]

  cd=Canonico_Documento[cd_id]
  ars=AnalisisRevisionSistematica.new(revision)
  decisiones=Decision.where(:usuario_id => usuario_id, :revision_sistematica_id => revision_id,
                            :etapa => etapa).as_hash(:canonico_documento_id)


  return partial(:decision, :locals => {revision: revision, cd: cd, decisiones: decisiones, ars: ars, usuario_id: usuario_id, etapa: etapa, ajax: true, only_buttons:only_buttons})


end