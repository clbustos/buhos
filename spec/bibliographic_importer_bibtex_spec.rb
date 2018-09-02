require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/bibtex"
describe 'BibliographicalImporter::BibTeX' do
  context "using WoS BibTeX" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(File.read("#{$base}/spec/fixtures/wos.bib"))
    end
    it "should retrieve 1 articles" do
      expect(@bib.records.length).to eq(1)
    end
    it "author should include Lenberg, Feldt and Wallgren" do
      %w{Lenberg Feldt Wallgren}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 3" do
      expect(@bib[0].authors.count).to eq(3)
    end
    it "title should be 'Behavioral software engineering: A definition and systematic literature review'" do
      expect(@bib[0].title).to eq("Behavioral software engineering: A definition and systematic literature review")
    end
    it "references should be 353" do
      expect(@bib[0].references_wos.count).to eq(353)
    end
  end

  context "using Scopus BibTeX" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(File.read("#{$base}/spec/fixtures/scopus.bib"))
    end
    it "should retrieve 1 articles" do
      expect(@bib.records.length).to eq(1)
    end
    it "author should include Lenberg, Feldt and Wallgren" do
      %w{Lenberg Feldt Wallgren}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "title should be 'Behavioral software engineering: A definition and systematic literature review'" do
      expect(@bib[0].title).to eq("Behavioral software engineering: A definition and systematic literature review")
    end
    it "references should be 358" do
      expect(@bib[0].references_scopus.count).to eq(358)
    end
  end

  context "using auto-generated BibTeX" do
    before(:context) do

      cds=[OpenStruct.new(id:1, title:"Title 1", abstract:"Abs", journal:"J1", year:2018, volume:1, pages:"1-2",
                          doi:"1", url:nil, author:"Levin, Tony and Gabriel, Peter")]
      bib_int=BibliographicalImporter::BibTex::Writer.generate(cds).to_s
      @bib=BibliographicalImporter::BibTex::Reader.parse(bib_int)

    end
    it "should retrieve 1 articles" do
      expect(@bib.records.length).to eq(1)
    end
    it "author should include Gabriel and Levin" do
      %w{Gabriel Levin}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "title should be 'Title 1'" do
      expect(@bib[0].title).to eq("Title 1")
    end
  end




end




