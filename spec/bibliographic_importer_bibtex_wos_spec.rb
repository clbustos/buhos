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
    it "year should be 2015" do
      expect(@bib[0].year).to eq("2015")
    end
    it "references should be 353" do
      expect(@bib[0].references_wos.count).to eq(353)
    end
    it "DOI should be correct " do
      expect(@bib[0].doi).to eq("10.1016/j.jss.2015.04.084")
    end
    it "wos_id should be correct " do
      expect(@bib[0].wos_id).to eq("ISI:000358699700002")
    end

  end



  context "when a new (2021) WoS BibTeX is used" do
    def text
      read_fixture("wos_2021.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)
    end
    it "should be a  Record_Wos" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::BibTex::Record_Wos)
    end


    it "should retrieve 1 article" do
      expect(@bib.records.length).to eq(1)
    end

    it "year should be 2010" do
      expect(@bib[0].year).to eq("2010")
    end
  end


  context "when a broken WoS BibTeX is used" do
    def text
      read_fixture("wos_wrong.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)
    end
    it "should retrieve 1 article" do
      expect(@bib.records.length).to eq(1)
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


  context "when a broken WoS BibTeX (2) is used" do
    def text
      read_fixture("wos_wrong_2.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)
    end
    it "should retrieve 2 article" do
      expect(@bib.records.length).to eq(2)
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

  context "when a broken WoS BibTeX (3) with extraneous encoding is used" do
    def text
      read_fixture("wos_wrong_3.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)
    end
    it "should retrieve 1 article" do
      expect(@bib.records.length).to eq(1)
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

end