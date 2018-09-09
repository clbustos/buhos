require 'spec_helper'

describe 'records resources' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_references
    login_admin
  end
  let(:record) {Record[1]}
  context "when record/:id is retrieved" do
    before do
      get '/record/1'
    end
    it "should be ok" do
      expect(last_response).to be_ok
    end
    it "should include record title" do
      expect(last_response.body).to include(record.title)
    end
  end

  context "when record/:id/search_crossref is retrieved" do
    before do
      get '/record/1/search_crossref'
    end
    it "should be ok" do
      expect(last_response).to be_ok
    end
    it "should include record title" do
      expect(last_response.body).to include(record.title)
    end
  end

  context "when record/:id/assign_doi is called" do
    before(:context) do
      Record[1].update(:doi=>nil)
      get "/record/1/assign_doi/#{doi_reference_1.gsub('/', '***')}"
    end
    it "should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should record include correct doi" do
      expect(record.doi).to eq(doi_reference_1)
    end
  end

  context "when record/:id/references_action is called" do
    before(:context) do
      @ref_4="REF4"
      create_references(texts:[@ref_4], record_id:1)
      post '/record/1/references_action', action:'delete', references:Reference.calculate_id(@ref_4)
    end
    it "should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should not be a record with ref_4 assigned to Record" do
      rr=RecordsReferences.where(record_id:1, reference_id:Reference.calculate_id(@ref_4))
      expect(rr.count).to eq(0)
    end
    after(:context) do
      Reference[Reference.calculate_id(@ref_4)].delete
    end
  end

  context "when /record/:id/manual_references is called" do
    def refs_news
      %w{REF1 REF2 REF3}
    end
    def refs_id
      refs_news.map {|v| Reference.calculate_id(v)}
    end
    before(:context) do

      post '/record/1/manual_references', :reference_manual=>refs_news.join("\n")
    end

    it "should create three new references" do
      expect(Reference.where(id:refs_id).count).to eq(3)
    end
    it "should create three new links between references and records" do
      expect(RecordsReferences.where(record_id:1, reference_id:refs_id).count).to eq(3)
    end

    after(:context) do
      RecordsReferences.where(record_id:1, reference_id:refs_id).delete
      Reference.where(:id=>refs_id)
    end

  end


end