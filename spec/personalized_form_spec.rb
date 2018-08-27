require 'spec_helper'

describe 'Analysis Form:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    SystematicReview.insert(:id=>1, :name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  def create_field_1
    post '/review/1/new_field', name:'field_1', order:1, description:'First question', type:'text' ,options:''
  end

  def create_field_2
    post '/review/1/new_field', name:'field_2', order:2, description:'Second question', type:'text' ,options:''
  end
  def bad_field_3
    post '/review/1/new_field', name:'field_3', order:3, description:'First question', type:'no_type' ,options:''
  end

  def delete_all_fields

  end
  context "when we retrieve the form custom fields for first time" do
    before(:context) do
      get '/review/1/fields'
    end
    it{expect(last_response).to be_ok}
  end
  context "when we add a new text field" do
    before(:context) do
      create_field_1
    end
    it "should redirect" do
      create_field_1
      expect(last_response).to be_redirect
    end
    it "should add a new field on database" do
      expect(SrField.where(:systematic_review_id=>1,:name=>'field_1').count).to eq(1)
    end
  end
  context "when we add a new text field with wrong type" do
    before(:context) do
      bad_field_3
    end
    it "should not be redirect" do
      expect(last_response).to_not be_redirect
    end
    it "should be status 500" do
      expect(last_response.status).to eq(500)
    end

    it "should not add a new field on database" do
      expect(SrField.where(:systematic_review_id=>1,:name=>'field_3').count).to eq(0)
    end
  end

  context "when we update the text field" do
    before(:context) do
      delete_all_fields
      create_field_2
      sr_id=SrField[:systematic_review_id=>1,:name=>'field_2'][:id]
      put "/review/edit_field/#{sr_id}/description", pk:sr_id, value:"new description"
    end
    it "should return ok" do
      expect(last_response).to be_ok
    end
    it "should update the field on the database" do
      expect(SrField[:systematic_review_id=>1,:name=>'field_2'][:description]).to eq 'new description'
    end
  end

  context "when we delete a tag" do
    before(:context) do
      SrField.where(:systematic_review_id=>1).delete
      delete_all_fields
      create_field_1
      create_field_2
      sr_id=SrField[:systematic_review_id=>1,:name=>'field_2'][:id]
      get "/review/1/field/#{sr_id}/delete"
    end
    it "should redirect" do
      expect(last_response).to be_redirect
    end
    it "should delete the field on the database" do
      expect(SrField[:systematic_review_id=>1,:name=>'field_2']).to be_nil
    end
  end

  context "when update analysis table" do
    before(:context) do
      SrField.where(:systematic_review_id=>1).delete
      delete_all_fields
      create_field_1
      create_field_2
      get '/review/1/update_field_table'
      #SrField.actualizar_tabla(SystematicReview[1])
    end
    let(:analysis_table)  {SystematicReview[1].analysis_cd_tn}
    let(:schema) {$db.schema(analysis_table)}
    it "should create an analysis table" do
      expect($db.tables.include? analysis_table.to_sym).to be true
    end
    it "should have 5 columns" do
      expect(schema.length).to eq(5)
    end

    it "should have correct name fields" do
      fields=[:id, :user_id, :canonical_document_id, :field_1, :field_2]
      expect(schema.map {|v| v[0]}).to eq(fields)
    end

  end

end
