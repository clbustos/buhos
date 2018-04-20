require 'spec_helper'
require_relative "../lib/pmc/doi_to_pmid_processor"
describe 'DoiToPmidProcessor' do
  before(:all) do
    @doi_list=['10.1093/nar/gks1195','10.3389/fpsyg.2018.00256','10.1037/0003-066X.63.1.32']
    @dtpp=PMC::DoiToPmidProcessor.new(@doi_list)
  end
  it ".doi_list should include '10.1093/nar/gks1195','10.3389/fpsyg.2018.00256'" do
    expect(@dtpp.doi_list).to eq(@doi_list)
  end
  it "#process shouldn't raise an error" do
    expect {@dtpp.process}.to_not raise_exception
  end
  context "when process a list of correct DOI" do
    before(:all) do
      @dtpp.process
    end
    it ".doi_as_pmid should have keys for three DOIs" do
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

  context "when process a list with an incorrect DOI" do
    before(:all) do
      @doi_bad=["INCORRECT","INCORRECT2"]
      @doi_2=@doi_list  + @doi_bad
      @dtpp2=PMC::DoiToPmidProcessor.new(@doi_2)

    end
    it "process should not raise an exception" do
      expect { @dtpp2.process }.to_not raise_exception
    end
    it ".doi_as_pmid should have keys for three DOIs" do
      expect(@dtpp2.doi_as_pmid.keys.sort).to eq(@doi_list.sort)
    end
    it ".doi_as_pmid should have values equal to correct PMID for known DOI" do
      expect(@dtpp2.doi_as_pmid['10.1093/nar/gks1195']).to eq("23193287")
      expect(@dtpp2.doi_as_pmid['10.3389/fpsyg.2018.00256']).to eq("29541051")
    end
    it ".doi_as_pmid should return nil for unknown DOI" do
      expect(@dtpp2.doi_as_pmid['10.1037/0003-066X.63.1.32']).to be_nil
    end
    it ".doi_as_pmid should return nil for incorrect DOI" do
      expect(@dtpp2.doi_as_pmid[  @doi_bad.first ]).to be_nil
    end
    it ".doi_bad should list of incorrect DOI" do

      expect(@dtpp2.doi_bad.sort).to eq(@doi_bad.sort)
    end

  end


end