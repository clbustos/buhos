require 'spec_helper'

describe 'Reference resources' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  def reference_doi
    Reference.exclude(:doi=>nil).first
  end
  def reference_wo_doi
    Reference["76e9503adf7e7b7b7b3248d3f6d467cabd179b8ce15d199bbb9018e046a23d45"]
  end

  context 'when reference with DOI is retrieved' do
    before(:context) do
      get "/reference/#{reference_doi[:id]}"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_doi[:id])
    end
    it "should show its DOI" do
      expect(last_response.body).to include(reference_doi[:doi])
    end

  end

  context "when similar references are retrieved from a reference with canonical" do
    before(:context) do
      get "/reference/#{reference_doi[:id]}/search_similar?distancia=10"
    end
    it "should response be ok" do
      $log.info(last_response.body)
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_doi[:id])
    end
    it "should show that are nothing similar without canonical" do
      expect(last_response.body).to include(I18n::t(:No_similar_references_without_canonical))
    end

  end

  context "when similar references are retrieved from a reference without canonical" do
    before(:context) do
      get "/reference/#{reference_wo_doi[:id]}/search_similar?distancia=20"
    end
    it "should response be ok" do
#      $log.info(last_response.body)
      expect(last_response).to be_ok
    end
    it "should show its code" do
      expect(last_response.body).to include(reference_wo_doi[:id])
    end
    it "should show that are similar references without canonical" do
      expect(last_response.body).to_not include(I18n::t(:No_similar_references_without_canonical))
    end
  end
  context "when assign DOI to a reference without it" do
    before(:context) do
      @doi=reference_doi.doi
      reference_doi.update(:doi=>nil)
      get "/reference/#{reference_doi[:id]}/assign_doi/#{@doi.gsub('/','***')}"
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "reference should have correct doi" do
      expect(reference_doi.doi).to eq(@doi)
    end
  end


end