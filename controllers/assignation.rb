put '/assignation/user/:user_id/review/:rs_id/cd/:cd_id/stage/:stage_id/edit_instruction' do |user_id, rs_id, cd_id,stage|
  halt_unless_auth('review_admin')

  pk = params['pk']
  value = params['value']
  Asignacion_Cd.where(:revision_sistematica_id=>rs_id, :canonico_documento_id=>cd_id, :usuario_id=>user_id, :etapa=>stage).update(:instruccion=>value.chomp)
  return true
end