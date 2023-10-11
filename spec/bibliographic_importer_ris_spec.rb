require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/ris"
describe 'BibliographicalImporter::Ris' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end

  context "using Lilac Ris" do
    before(:context) do
      @bib=BibliographicalImporter::Ris::Reader.parse( read_fixture("lilacs_test.ris") )

    end
    it "should be a  Ris::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::Ris::Record)
    end
    it "should retrieve 5 articles" do
      expect(@bib.records.length).to eq(5)
    end
    it "author should include " do
      %w{Fernández Vásquez Ortega}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 3" do
      expect(@bib[0].authors.count).to eq(3)
    end
    it "title should be 'Behavioral software engineering: A definition and systematic literature review'" do
      expect(@bib[0].title.include? "Stressors").to be_truthy
    end
    it "year should be 2015" do
		expect(@bib[0].year).to eq("2021")
    end
    it "DOI should be correct " do
      expect(@bib[0].doi).to eq("10.22201/eneo.23958421e.2021.2.934")
    end
  end



  context "using Proquest Ris" do
    before(:context) do
      @bib=BibliographicalImporter::Ris::Reader.parse( read_fixture("proquest_test.ris") )

    end
    it "should be a  Ris::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::Ris::Record)
    end
    it "should retrieve 5 articles" do
      expect(@bib.records.length).to eq(11)
    end
    it "author should include " do
      %w{Picón-Jaime}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 8" do
      expect(@bib[0].authors.count).to eq(8)
    end
    it "title should include 'Perception of Physicians'" do
      expect(@bib[0].title.include? "Perception of Physicians").to be_truthy
    end
    it "year should be 2022" do
      expect(@bib[0].year).to eq("2022")
    end
    it "DOI should be correct " do
      expect(@bib[0].doi).to eq("https://doi.org/10.1177/21501319221121462")
    end
  end

  context "using WoS Ris" do
    before(:context) do
      @bib=BibliographicalImporter::Ris::Reader.parse( read_fixture("wos.ris") )
    end
    it "should be a  Ris::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::Ris::Record)
    end
    it "should retrieve 5 articles" do
      expect(@bib.records.length).to eq(4)
    end
    it "author should include " do
      %w{Sánchez-García Gilabert Calvo-Manzano}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 3" do
      expect(@bib[0].authors.count).to eq(3)
    end
    it "title should be correct" do
      expect(@bib[0].title.include? "Countermeasures and their taxonomies").to be_truthy
    end
    it "year should be 2023" do
      expect(@bib[0].year).to eq("2023")
    end
    it "DOI should be correct " do
      expect(@bib[0].doi).to eq("10.1016/j.cose.2023.103170")
    end
  end

end




