require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/bibtex"
describe 'BibliographicalImporter::BibTeX' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end
  context "using Ebscohost with error (3) BibTeX " do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse( read_fixture("EBSCO_wrong_3.bib") )

    end
    it "should be a  Record_Ebscohost" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::BibTex::Record_Ebscohost)
    end
    it "should retrieve 1 articles" do
      expect(@bib.records.length).to eq(26)
    end
    it "author should include Lenberg, Feldt and Wallgren" do
      %w{Yang Qingtai Mingyi Quan}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 3" do
      expect(@bib[0].authors.count).to eq(4)
    end
    it "title should be correct" do
      expect(@bib[0].title).to eq("Knowledge mapping of students' mental health status in the COVID-19 pandemic: A bibliometric study.")
    end
    it "year should be 2022" do
      expect(@bib[0].year).to eq("2022")
    end
    it "year should be 2022" do
      expect(@bib[0].uid).to eq("id=2272c03f-3f9d-304d-99d7-a476025d7598")
    end
  end
end