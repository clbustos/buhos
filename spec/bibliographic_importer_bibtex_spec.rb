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
    it "DOI shouldn't have any brackets " do

      dois=@bib.find_all {|record| !record.doi.nil? and record.doi=~/[{}]/}
      expect(dois.map {|d|d.doi}).to eq([])

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
    it "year should be 2019" do
      expect(@bib[0].year).to eq("2019")
    end

    it "journal should be 'Revista Portuguesa de Educação'" do
      expect(@bib[0].journal).to eq("Revista Portuguesa de Educação")
    end
    it "DOI shouldn't have any brackets " do

      dois=@bib.find_all {|record| !record.doi.nil? and record.doi=~/[{}]/}
      expect(dois.map {|d|d.doi}).to eq([])

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

  context "when a erroneus Ebscohost is used" do
    def text
      read_fixture("EBSCO_wrong_2.bib")
    end
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(text)
    end
    it "should retrieve 1 article" do
      expect(@bib.records.length).to eq(1)
    end

    it "title should be correct" do
      expect(@bib.records[0].title).to include("La labor docente de las profesoras")
    end

    it "year should be correct" do
      expect(@bib.records[0].year).to eq("2023")
    end
    it "volume should be correct" do
      expect(@bib.records[0].volume).to eq("50")
    end
  end


  context "using auto-generated BibTeX" do
    before(:context) do
      cds=[OpenStruct.new(id:1, title:"{Title} {number} 1", abstract:"Abs", journal:"{Journal} of {MANAGEMENT}",
                          year:2018, volume:1, pages:"1-2",
                          doi:"1", url:nil, author:"Levin, Tony and Gabriel, Peter",
                          scopus_id:"scopus-1",
                          wos_id:"wos-1",
                          scielo_id:"scielo-1")]
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
    it "scielo_id should be 'scielo-1'" do
      expect(@bib[0].scielo_id).to eq("scielo-1")
    end
    it "wos_id should be 'wos-1'" do
      expect(@bib[0].wos_id).to eq("wos-1")
    end

    it "scopus_id should be 'scopus-1'" do
      expect(@bib[0].scopus_id).to eq("scopus-1")
    end

  end




end




