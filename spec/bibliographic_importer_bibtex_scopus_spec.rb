require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/bibtex"
describe 'BibliographicalImporter::BibTeX' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
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


  context "when a broken Scopus BibTeX is used (version 5)" do
    def text
      read_fixture("scopus_wrong_5.bib")
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
