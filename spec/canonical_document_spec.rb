require 'spec_helper'

describe 'Canonical Record' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  context "when search for crossref references" do
    before(:context) do
      get '/canonical_document/64/search_crossref_references'
    end
    it {expect(last_response).to be_redirect}
  end
  context "when search for crossref data" do
    before(:context) do
      get '/canonical_document/64/get_crossref_data'
    end
    it {expect(last_response).to be_redirect}
  end

  context "when cleaning references for canonical document" do
    before(:context) do
      get '/canonical_document/64/clean_references'
    end
    it {expect(last_response).to be_redirect}
    it "should be no references assigned to the canonical document" do
      expect(Referencia.where(canonico_documento_id:64).count).to eq(0)
    end
  end

end