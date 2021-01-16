# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2021, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Analysis form


# List of personalized fields
get '/review/:rs_id/fields' do |rs_id|
  halt_unless_auth('review_view')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review

  @campos=@review.fields

  @xselect=get_xeditable_select(SrField.types_hash, "/review/edit_field/nil/type", 'select-type')
  haml %s{systematic_reviews/fields}
end

# Add a new field

post '/review/:rs_id/new_field' do |rs_id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review

  name=params['name'].chomp

  @campo_previo=@review.fields.where(:name=>name)
  if @campo_previo.empty?

    type=params['type'].chomp

    halt 500, "Not valid type #{type}" unless SrField.is_valid_type?(type)

    SrField.insert(:systematic_review_id=>rs_id, :order=>params['order'],:name=>name, :description=>params['description'], :type=>type,:options=>params['options'])
    add_message(t('sr_new_sr_edit_field.doesnt_existfield.success', name:params['name']))

  else
    add_message(t('sr_new_field.duplicated', name:params['name']), :error)
  end
  redirect back
end

# Edit specific attribute of a field
put '/review/edit_field/:attr_id/:attr' do |attr_id,attr|
  halt_unless_auth('review_admin')
  return [500, t('sr_edit_field.invalid', field:attr)] unless %w{order name description type options}.include? attr
  pk = params['pk']
  value = params['value']
  campo_o=SrField[pk]
  return [t('sr_edit_field.doesnt_exist_db', field_id:attr_id)] unless attr
  campo_o.update({attr.to_sym=>value})
  return 200
end

# Update analysis table, using information provide on fields
get '/review/:rs_id/update_field_table' do |rs_id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rs_id]
  raise Buhos::NoReviewIdError, rs_id if !@review
  @campos=@review.fields
  SrField.update_table(@review)
  add_message(t("fields.sr_table_update_success"))
  redirect back
end

# Delete a field
get '/review/:rs_id/field/:fid/delete' do  |rs_id, fid|
  halt_unless_auth('review_admin')
  sr_field=SrField[fid]
  name=sr_field[:name]
  return 404 if !sr_field
  sr_field.delete
  add_message(t("fields.field_deleted", name:name))
  redirect back
end

# @!endgroup