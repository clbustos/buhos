require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/bibtex"
describe 'BibliographicalImporter::BibTeX' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end
  context "using WoS BibTeX" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse( read_fixture("wos.bib") )

    end
    it "should be a  Record_Wos" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::BibTex::Record_Wos)
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
      @bib=BibliographicalImporter::BibTex::Reader.parse(read_fixture("scopus.bib"))
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

  context "when a broken Scopus BibTeX is used" do
    def text
      read_fixture("scopus_wrong.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)

    end
    it "should retrieve 11 articles" do
      expect(@bib.records.length).to eq(11)
    end
    it "no title should be excluded" do
      titulos=text.each_line.inject([]) {|ac,v|
        if v=~/^title=\{(.+?)\}/
          ac.push($1)
        end
        ac
      }
      h=@bib.records.find_all do |record|
        !record.title.nil?
      end

      expect((titulos-h.map {|v| v.title})).to eq([])
    end
    it "no author should be excluded" do
      author=text.each_line.inject([]) {|ac,v|
        if v=~/^author=\{(.+?)\}/
          ac.push($1)
        end
        ac
      }
      h=@bib.records.find_all do |record|
        !record.author.nil?
      end

      expect((author-h.map {|v| v.author})).to eq([])
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




