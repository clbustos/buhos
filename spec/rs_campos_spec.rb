require 'spec_helper'

describe 'Rs_Campo' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    $db.run "DROP TABLE IF EXISTS analisis_rs_1 "
    login_admin
  end

  context "when update analysis table" do
    before(:context) do
      SrField.actualizar_tabla(SystematicReview[1])
    end
    let(:analysis_table)  {SystematicReview[1].analisis_cd_tn}
    let(:schema) {$db.schema(analysis_table)}
    it "should create an analysis table" do
      expect($db.tables.include? analysis_table.to_sym).to be true
    end
    it "should have 6 columns" do
      expect(schema.length).to eq(6)
    end

    it "should have correct name fields" do
      fields=[:id, :user_id, :canonical_document_id, :tools, :features, :stages]
      expect(schema.map {|v| v[0]}).to eq(fields)
    end

  end

end