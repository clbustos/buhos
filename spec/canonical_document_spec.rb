require 'spec_helper'



describe 'Canonical Document' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_references
    Search[1].update(:valid=>true)
    CanonicalDocument[1].update(:title=>'This is the title for CD1', :doi=>'10.14257/ijseia.2016.10.1.16')
    $db[:crossref_dois].insert(:doi=>'10.14257/ijseia.2016.10.1.16',:json=>read_fixture("crossref_ex_1.json"))
    login_admin
  end


  context "when /review/:sr_id/:action/cd/:cd_id/by_similarity is used to continue with another canonical document on extraction" do
    before(:context)  do
      get '/review/1/extract_information/cd/1/by_similarity'
    end
    let(:cd) {CanonicalDocument[1]}
    it "should redirect" do
      expect(last_response).to be_redirect
    end
  end

  context "when view crossref information of a canonical document" do
    before(:context) do
      get '/canonical_document/1/view_crossref_info'
    end
    let(:cd) {CanonicalDocument[1]}
    let(:cr) {CanonicalDocument[1].crossref_integrator}
    it "should contain information about title" do
      expect(last_response.body).to include(cr.title)
    end

    it "should not alert that no DOI is available" do
      expect(last_response.body).to_not include(I18n::t(:No_DOI_to_obtain_information_from_Crossref))
    end


  end


  context "when cleaning references for canonical document" do
    before(:context) do
      get '/canonical_document/1/clean_references'
    end
    it {expect(last_response).to be_redirect}
    it "should be no references assigned to the canonical document" do
      expect(Reference.where(canonical_document_id:1).count).to eq(0)
    end
  end


  context "when edit a canonical document using form" do
    before(:context) do
      put '/canonical_document/edit_field/title', pk:1,value:'New Title'
    end
    it "response should be ok" do expect(last_response).to be_ok end
    it "object should have new title" do
      expect(CanonicalDocument[1].title).to eq('New Title')
    end
  end

  context "when view information about a  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/1"; last_response}
    it "response should be ok" do expect(page).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include CanonicalDocument[1].title
    end
  end



  context "when view information about cites to canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/1/cites"; last_response}
    it "response should be ok" do expect(page).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include I18n::t(:Without_canonical_document)
    end
  end

  context "when view information about articles cited by  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/1/cited_by"; last_response}
    it "response should be ok" do expect(page).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include I18n::t(:Without_canonical_document)
    end
  end

  context "when view information about articles cited by rtr  canonical document assigned to a systematic review" do
    let(:page) {get "/review/1/canonical_document/1/cited_by_rtr"; last_response}
    it "response should be ok" do expect(page).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include I18n::t(:Without_canonical_document)
    end
  end

  context "when view Pubmed info for a canonical document" do
    let(:page) {get "/canonical_document/1/view_pubmed_info"; last_response}
    it "response should be ok" do expect(page).to be_ok end
    it "should include title of canonical document" do
      expect(page.body).to include CanonicalDocument[1].title
    end
  end
end

describe "Canonical Document without DOI" do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite

    sr_references
    Search[1].update(:valid=>true)
    CanonicalDocument[1].update(:title=>'This is the title for CD1')
    login_admin
  end

  context 'when canonical_document/X/view_crossref_info is called' do
    before do
      get '/canonical_document/1/view_crossref_info'
    end
    it "should return a correct page" do
      expect(last_response).to be_ok
    end
    it "should alert that no DOI is available" do
      expect(last_response.body).to include(I18n::t(:No_DOI_to_obtain_information_from_Crossref))
    end

  end
end

describe 'Canonical Document not available' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite

    sr_references
    Search[1].update(:valid=>true)
    CanonicalDocument[1].update(:title=>'This is the title for CD1', :doi=>'10.14257/ijseia.2016.10.1.16')

    login_admin
  end
  pages=['/review/1/extract_information/cd/2/by_similarity',
  '/canonical_document/2/view_crossref_info',
  '/canonical_document/2/clean_references',
  '/review/1/canonical_document/2',
  '/review/1/canonical_document/2/cites'
  ]
  pages.each do |page|
    context "when #{page} is called" do
      it "should return 404 error" do
        get page
        expect(last_response.status).to eq(404)
      end
    end

  end

end