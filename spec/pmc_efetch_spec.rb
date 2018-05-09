require 'spec_helper'
require_relative "../lib/pmc/efetch"
describe 'PMC::Efetch' do
  before(:all) do
    @pmid_list=['23193287','29541051']
    @efetch=PMC::Efetch.new(@pmid_list)
  end
  it ".pmid_list should include '23193287','29541051'" do
    expect(@efetch.pmid_list).to eq(@pmid_list)
  end
  it "#process shouldn't raise an error" do
    skip if !ENV['NCBI_API_KEY']; expect {@efetch.process}.to_not raise_exception
  end
  context "when process a list of correct DOI" do
    before(:all) do
      skip if !ENV['NCBI_API_KEY']; @efetch.process
    end
    it ".pmid_xml should be an PMC::EfetchXMLSummaries" do
      skip if !ENV['NCBI_API_KEY'];expect(@efetch.pmid_xml).to be_a(PMC::EfetchXMLSummaries)
    end
    it ".pmid_xml[0] should be a Nokogiri Object" do
      skip if !ENV['NCBI_API_KEY'];expect(@efetch.pmid_xml[0]).to be_a(Nokogiri::XML::Document)
    end
  end
end
