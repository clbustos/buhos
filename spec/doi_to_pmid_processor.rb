require 'spec_helper'
require_relative "../lib/doi_to_pmid_processor"
describe 'DoiToPmidProcessor' do
  before(:all) do
    @doi_list=['10.1093/nar/gks1195','10.3389/fpsyg.2018.00256','10.1037/0003-066X.63.1.32']
    @dtpp=DoiToPmidProcessor.new(@doi_list)
  end
  it ".doi_list should include '10.1093/nar/gks1195','10.3389/fpsyg.2018.00256'" do
    expect(@dtpp.doi_list).to eq(@doi_list)
  end
  it "#process shouldn't raise an error" do
    expect {@dtpp.process}.to_not raise_exception
  end
  context "when processed" do
    before(:all) do
      @dtpp.process
    end
    it ".doi_as_pmid should have keys for both DOIs" do
      expect(@dtpp.doi_as_pmid.keys.sort).to eq(@doi_list.sort)
    end
    it ".doi_as_pmid should have values equal to correct PMID for known DOI" do
      expect(@dtpp.doi_as_pmid['10.1093/nar/gks1195']).to eq("23193287")
      expect(@dtpp.doi_as_pmid['10.3389/fpsyg.2018.00256']).to eq("29541051")
    end
    it ".doi_as_pmid should return nil for unknown DOI" do
      expect(@dtpp.doi_as_pmid['10.1037/0003-066X.63.1.32']).to be_nil
    end

  end


end