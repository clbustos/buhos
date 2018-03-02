get '/review/:rs_id/fields' do |rs_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review

  @campos=@review.fields
  haml %s{systematic_reviews/fields}
end

post '/review/:rs_id/new_field' do |rs_id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review

  name=params['name'].chomp

  @campo_previo=@review.fields.where(:name=>name)
  if @campo_previo.empty?
    SrField.insert(:systematic_review_id=>rs_id, :order=>params['order'],:name=>name, :description=>params['description'], :type=>params['tipo'].chomp,:opciones=>params['opciones'])
    add_message(t('sr_new_sr_edit_field.doesnt_existfield.success', name:params['name']))

  else
    add_message(t('sr_new_field.duplicated', name:params['name']), :error)
  end
  redirect back
end

put '/review/edit_field/:campo_id/:campo' do |campo_id,campo|
  halt_unless_auth('review_admin')
  return [500, t('sr_edit_field.invalid', field:campo)] unless %w{order name description tipo opciones}.include? campo
  pk = params['pk']
  value = params['value']
  campo_o=Rs_Campo[pk]
  return [t('sr_edit_field.doesnt_exist_db', field_id:campo_id)] unless campo
  campo_o.update({campo.to_sym=>value})
  return 200
end


get '/review/:rs_id/update_field_table' do |rs_id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  @campos=@review.fields
  SrField.actualizar_tabla(@review)
  add_message(t("fields.sr_table_update_success"))
  redirect back
end


get '/review/:rs_id/field/:fid/delete' do  |rs_id, fid|
  halt_unless_auth('review_admin')
  sr_field=Rs_Campo[fid]
  name=sr_field[:name]
  return 404 if !sr_field
  sr_field.delete
  add_message(t("fields.field_deleted", name:name))
  redirect back
end