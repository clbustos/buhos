require_relative 'spec_helper'

# This test is VERY important. If works, allow us to decouple database schemas between tests
# Sequel manual warns about doing this, but I have no choice to allow unified testing with Rspec.
#
describe 'Buhos::DBAdapter' do

  let(:db1) {Buhos::SchemaCreation.create_db_from_scratch(Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false))}
  let(:db2) {Buhos::SchemaCreation.create_db_from_scratch(Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false))}

  it '.use_db change the db on Sequel::Model associations' do

    $db_adapter.use_db(db1)
    $db_adapter.update_model_association
    expect(Usuario.db).to equal(db1)
    $db_adapter.use_db(db2)
    $db_adapter.update_model_association
    expect(Usuario.db).to equal(db2)
  end

  it 'allows to change model without interference between tests' do
  $db_adapter.use_db(db1)
  $db_adapter.update_model_association
    expect(Usuario.all.count).to eq(3)
    Usuario.insert(:login=>"New user",:password=>2, :rol_id=>'administrator')
    expect(Usuario.all.count).to eq(4)
    expect(Usuario.where(:login=>'New user').count).to eq(1)

    $db_adapter.use_db(db2)
    $db_adapter.update_model_association
    expect(Usuario.where(:login=>'New user').count).to eq(0)
    expect(Usuario.all.count).to eq(3)
    Usuario.insert(:login=>"New user",:password=>2, :rol_id=>'administrator')
    expect(Usuario.all.count).to eq(4)
  $db_adapter.use_db(db1)
  $db_adapter.update_model_association
  expect(Usuario.where(:login=>'New user').count).to eq(1)


  end
end