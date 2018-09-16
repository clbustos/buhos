require 'spec_helper'

describe 'Search on canonical documents' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    Search[1].update(:valid=>true)
    CanonicalDocument[1].update(:title=>'This is the title')
    login_admin
  end

  context "when /review/:id/canonical_documents is called with a complete query" do
    before(:context) do
      get "/review/1/canonical_documents", :query=>"title(This is the title)"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should include document in body" do
      expect(last_response.body).to include("canonical-document-1")
    end
  end




  context "when /review/:id/canonical_documents is called with a only title query" do
    before(:context) do
      get "/review/1/canonical_documents", :query=>"This is the title"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should include document in body" do
      expect(last_response.body).to include("canonical-document-1")
    end

  end

  context "when /review/:id/canonical_documents is called with a bad query" do
    before(:context) do
      get "/review/1/canonical_documents", :query=>"title(This is the title"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should not include document in body" do
      expect(last_response.body).to_not include("canonical-document-1")
    end

  end

end