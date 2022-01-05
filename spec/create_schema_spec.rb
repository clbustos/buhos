require_relative 'spec_helper'



describe 'Buhos::SchemaCreation' do

  context '#create_db_from_scratch' do
    let(:db) {Buhos::SchemaCreation.create_db_from_scratch("sqlite::memory:")}
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
    it "create 8 bibliographic databases" do
      expect(db["SELECT * FROM bibliographic_databases"].all.count).to eq(8)
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

    it "create 8 bibliographic databases" do
      expect(db["SELECT * FROM bibliographic_databases"].all.count).to eq(8)
    end
  end

end