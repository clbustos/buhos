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
    expect {@efetch.process}.to_not raise_exception
  end
  context "when process a list of correct DOI" do
    before(:all) do
      @efetch.process
    end

  end



end