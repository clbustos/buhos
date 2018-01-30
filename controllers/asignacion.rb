put '/asignacion/usuario/:user_id/revision/:rs_id/cd/:cd_id/stage/:stage_id/editar_instruccion' do |user_id, rs_id, cd_id,stage|
  pk = params['pk']
  value = params['value']
  Asignacion_Cd.where(:revision_sistematica_id=>rs_id, :canonico_documento_id=>cd_id, :usuario_id=>user_id, :etapa=>stage).update(:instruccion=>value.chomp)
  return true
end