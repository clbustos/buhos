require 'spec_helper'

describe 'Canonical Document' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end


  context "when view crossref information of a canonical document" do
    before(:context) do
      get '/canonical_document/64/view_crossref_info'
    end
    let(:cd) {CanonicalDocument[64]}
    let(:cr) {CanonicalDocument[64].crossref_integrator}
    it "should contain information about title" do
      expect(last_response.body).to include(cr.title)
    end
  end


  context "when cleaning references for canonical document" do
    before(:context) do
      get '/canonical_document/64/clean_references'
    end
    it {expect(last_response).to be_redirect}
    it "should be no references assigned to the canonical document" do
      expect(Reference.where(canonical_document_id:64).count).to eq(0)
    end
  end


  context "when edit a canonical document using form" do
    before(:context) do
      put '/canonical_document/edit_field/title', pk:64,value:'New Title'
    end
    it "response should be ok" do expect(last_response).to be_ok end
    it "object should have new title" do
      expect(CanonicalDocument[64].title).to eq('New Title')
    end
  end

  context "when view information about a  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/64"; last_response}
    it "response should be ok" do expect(last_response).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include CanonicalDocument[64].title
    end
  end



  context "when view information about cites to canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/64/cites"; last_response}
    it "response should be ok" do expect(last_response).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include "&nbsp;15"
    end
  end

  context "when view information about articles cited by  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/64/cited_by"; last_response}
    it "response should be ok" do expect(last_response).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include I18n::t(:Without_canonical_document)
    end
  end

  context "when view information about articles cited by rtr  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/64/cited_by_rtr"; last_response}
    it "response should be ok" do expect(last_response).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include I18n::t(:Without_canonical_document)
    end
  end

  context "when view Pubmed info for a canonical document" do
    let(:page) {get "/canonical_document/64/view_pubmed_info"; last_response}
    it "response should be ok" do expect(last_response).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include CanonicalDocument[64].title
    end
  end




end