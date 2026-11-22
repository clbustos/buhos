require_relative 'spec_helper'



describe 'Buhos::SchemaCreation' do
  def expect_registration_roles(db)
    grants=db[:authorizations_roles]
    %w[independent_researcher review_collaborator].each do |role_id|
      expect(db[:roles][id: role_id]).not_to be_nil
      expect(grants.where(role_id: role_id).select_map(:authorization_id)).to match_array(%w[group_view review_view])
    end
    expect(db[:authorizations][id: 'registration_admin']).not_to be_nil
    expect(grants.where(authorization_id: 'registration_admin').select_map(:role_id)).to eq(['administrator'])
  end

  context 'registration roles and permissions' do
    let(:db) { Sequel.sqlite }
    let(:migrations) { File.expand_path('../db/migrations', __dir__) }

    before { Buhos::SchemaCreation.create_schema(db) }
    after { db.disconnect }

    it 'seeds the roles and grants through bootstrap and accepts subsequent migrations' do
      Sequel::Migrator.run(db, migrations, target: 32)
      Buhos::SchemaCreation.create_bootstrap_data(db)
      expect_registration_roles(db)
      Sequel::Migrator.run(db, migrations)
      expect_registration_roles(db)
    end

    it 'repairs missing registration roles and grants in an already migrated database' do
      Sequel::Migrator.run(db, migrations, target: 35)
      Buhos::SchemaCreation.create_bootstrap_data(db)
      db[:authorizations_roles].where(role_id: 'review_collaborator').delete
      db[:roles].where(id: 'review_collaborator').delete
      db[:authorizations_roles].where(role_id: 'independent_researcher', authorization_id: 'group_view').delete
      db[:authorizations_roles].where(authorization_id: 'registration_admin').delete
      db[:authorizations].where(id: 'registration_admin').delete

      Sequel::Migrator.run(db, migrations)
      expect_registration_roles(db)
    end
  end

  context '#create_db_from_scratch' do
    let(:db) {Buhos::SchemaCreation.create_db_from_scratch("sqlite::memory:")}
    it "create three users" do
      expect(db["SELECT * FROM users"].all.count).to eq(3)
    end
    it 'creates the registration roles and grants' do
      expect_registration_roles(db)
    end
    it "create two groups" do
      expect(db["SELECT * FROM groups"].all.count).to eq(2)
    end
    it "create 6 taxonomies" do
      expect(db["SELECT * FROM sr_taxonomies"].all.count).to eq(6)
    end
    it "create 20 categories" do
      expect(db["SELECT * FROM sr_taxonomy_categories"].all.count).to eq(20)
    end
    it "create correct number of  bibliographic databases" do
      expect(db["SELECT * FROM bibliographic_databases"].all.count).to eq(Buhos::SchemaCreation::BIBLIOGRAPHICAL_DATABASES.length)
    end
  end
  context '#create_db_from_scratch applied twice' do
    before(:all) do

      @db_local=Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false)

      Buhos::SchemaCreation.create_db_from_scratch(@db_local)
      Buhos::SchemaCreation.create_db_from_scratch(@db_local)
    end
    let(:db) {@db_local}
    it "create three users" do
      expect(db["SELECT * FROM users"].all.count).to eq(3)
    end
    it "create two groups" do
      expect(db["SELECT * FROM groups"].all.count).to eq(2)
    end
    it "create 6 taxonomies" do
      expect(db["SELECT * FROM sr_taxonomies"].all.count).to eq(6)
    end
    it "create 20 categories" do
      expect(db["SELECT * FROM sr_taxonomy_categories"].all.count).to eq(20)
    end

    it "create correct bibliographic databases" do
      expect(db["SELECT * FROM bibliographic_databases"].all.count).to eq(Buhos::SchemaCreation::BIBLIOGRAPHICAL_DATABASES.length)
    end
  end

end
