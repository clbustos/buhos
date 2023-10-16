require 'spec_helper'
require_relative "../lib/bibliographical_importer/csv"
describe 'BibliographicalImporter::CSV generic' do
  context "using Bsv export" do
    before(:all) do
      @bib=BibliographicalImporter::CSV::Reader.parse(File.read("#{$base}/spec/fixtures/bvs_ingles.csv"),'generic')
    end
    it "should retrieve 13 articles" do
      expect(@bib.records.length).to eq(13)
    end
    it "first author should be correct" do
      expect(@bib[0].author).to eq("Blum, Gabriela Brendel and Bins, Rafael Bittencourt and Rabelo-da-Ponte, Francisco Diego and Passos, Ives Cavalcante")
    end

    it "last doi should be correct" do
      expect(@bib[12].doi).to eq("10.1002/jts.21772")
    end
  end

  context "using Scielo export" do
    before(:all) do
      @bib=BibliographicalImporter::CSV::Reader.parse(File.read("#{$base}/spec/fixtures/scielo_export.csv"),'scielo')
    end
    it "should retrieve 15 articles" do
      expect(@bib.records.length).to eq(15)
    end
    it "first year should be correct" do
      expect(@bib[0].year).to eq("2023")
    end

    it "first author should be correct" do
      expect(@bib[0].author).to eq("Maldonado Alegre and Fernando Camilo and Ulloa Córdova and Vanessa Dora and Príncipe Concha and Betty and Trujillo-Solis and Beymar Pedro")
    end

    it "last url should be correct" do
      expect(@bib[14].url).to eq("http://www.scielo.org.co/scielo.php?script=sci_arttext&pid=S0121-56122021000300139&lang=pt")
    end
  end



end
