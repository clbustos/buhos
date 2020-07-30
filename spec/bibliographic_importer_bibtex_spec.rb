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

  context "using Scielo BibTeX" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(read_fixture("scielo.bib"))
    end
    it "first record should be a Scielo Record" do
      expect(@bib[0]).to be_instance_of(BibliographicalImporter::BibTex::Record_Scielo)
    end
    it "should retrieve 13 articles" do
      expect(@bib.records.length).to eq(13)
    end
    it "author should include Oliveira and Viviani" do
      %w{Oliveira Viviani}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "title should be 'Entre a fralda e a lousa: A questão das identidades docentes em berçários'" do
      expect(@bib[0].title).to eq("Entre a fralda e a lousa: A questão das identidades docentes em berçários")
    end
    it "journal should be 'Revista Portuguesa de Educação'" do
      expect(@bib[0].journal).to eq("Revista Portuguesa de Educação")
    end

  end


  context "when a broken Scopus BibTeX is used (version 1)" do
    def text
      read_fixture("scopus_wrong_1.bib")
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

  context "when a broken Scopus BibTeX is used (version 2)" do
    def text
      read_fixture("scopus_wrong_2.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)

    end
    it "should retrieve 34 articles" do
      expect(@bib.records.length).to eq(37)
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



  context "when a BibTeX with ISO-8859-1 is used" do
    def text
      read_fixture("encoding_iso_8859_1.bib").encode("UTF-8", invalid: :replace, replace:"?")
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

      h=@bib.records.find_all do |record|
        !record.author.nil?
      end
      expect((h.map {|v| v.author})).to eq(["{Cleland-Huang}, J. and {M?der}, P. and {Mirakhorli}, M. and {Amornborvornwong}, S."])
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



  context "using auto-generated BibTeX" do
    before(:context) do
      cds=[OpenStruct.new(id:1, title:"{Title} {number} 1", abstract:"Abs", journal:"{Journal} of {MANAGEMENT}", year:2018, volume:1, pages:"1-2",
                          doi:"1", url:nil, author:"Levin, Tony and Gabriel, Peter")]
      bib_int=BibliographicalImporter::BibTex::Writer.generate(cds).to_s
      #p bib_int
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
    it "title should be 'Title number 1'" do
      expect(@bib[0].title).to eq("Title number 1")
    end
    it "journal should be 'Journal of MANAGEMENT'" do
      expect(@bib[0].journal).to eq("Journal of MANAGEMENT")
    end
  end




end




