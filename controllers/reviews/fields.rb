get '/review/:rs_id/fields' do |rs_id|
  halt_unless_auth('review_view')
  @revision=Revision_Sistematica[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@revision

  @campos=@revision.fields
  haml %s{systematic_reviews/fields}
end

post '/review/:rs_id/new_field' do |rs_id|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@revision

  nombre=params['nombre'].chomp

  @campo_previo=@revision.fields.where(:nombre=>nombre)
  if @campo_previo.empty?
    Rs_Campo.insert(:revision_sistematica_id=>rs_id, :orden=>params['orden'],:nombre=>nombre, :descripcion=>params['descripcion'], :tipo=>params['tipo'].chomp,:opciones=>params['opciones'])
    add_message(t('sr_new_sr_edit_field.doesnt_existfield.success', name:params['nombre']))

  else
    add_message(t('sr_new_field.duplicated', name:params['nombre']), :error)
  end
  redirect back
end

put '/review/edit_field/:campo_id/:campo' do |campo_id,campo|
  halt_unless_auth('review_admin')
  return [500, t('sr_edit_field.invalid', field:campo)] unless %w{orden nombre descripcion tipo opciones}.include? campo
  pk = params['pk']
  value = params['value']
  campo_o=Rs_Campo[pk]
  return [t('sr_edit_field.doesnt_exist_db', field_id:campo_id)] unless campo
  campo_o.update({campo.to_sym=>value})
  return 200
end


get '/review/:rs_id/update_field_table' do |rs_id|
  halt_unless_auth('review_admin')
  @revision=Revision_Sistematica[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@revision
  @campos=@revision.fields
  Rs_Campo.actualizar_tabla(@revision)
  add_message(t("fields.sr_table_update_success"))
  redirect back
end


get '/review/:rs_id/field/:fid/delete' do  |rs_id, fid|
  halt_unless_auth('review_admin')
  sr_field=Rs_Campo[fid]
  name=sr_field[:nombre]
  return 404 if !sr_field
  sr_field.delete
  add_message(t("fields.field_deleted", name:name))
  redirect back
end