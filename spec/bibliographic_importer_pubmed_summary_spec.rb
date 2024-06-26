require 'spec_helper'
require 'ostruct'
require_relative "../lib/bibliographical_importer/pubmed_summary"

describe 'BibliographicalImporter::PubmedSummary' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end
  context "using Pubmed nbib with one article" do
    before(:context) do
      @bib=BibliographicalImporter::PubmedSummary::Reader.parse( read_fixture("pubmed-30080086.nbib") )
    end
    it "should be a  PubmedSummary::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::PubmedSummary::Record)
    end
    it "should retrieve 1 article" do
      expect(@bib.records.length).to eq(1)
    end
    it "author should include Hom, Melanie A and Davis, Lisa and Joiner, Thomas E" do
      %w{Hom Davis Joiner}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "authors should be 3" do
      expect(@bib[0].authors.count).to eq(3)
    end
    it "title should be 'Survivors of suicide attempts (SOSA) support group: Preliminary findings from an open-label trial'" do
      expect(@bib[0].title).to eq("Survivors of suicide attempts (SOSA) support group: Preliminary findings from an open-label trial.")
    end
    it "doi  should be '10.1037/ser0000195'" do
      expect(@bib[0].doi).to eq("10.1037/ser0000195")
    end
    it "pubmed  should be '30080086'" do
      expect(@bib[0].pubmed_id).to eq("30080086")
    end
    it "keywords  should be an Array" do
      expect(@bib[0].pubmed_id).to eq("30080086")
    end

  end

  context "using Pubmed nbib with many articles" do
    before(:context) do
      @bib=BibliographicalImporter::PubmedSummary::Reader.parse( read_fixture("pubmed-heartattac-set.nbib") )
    end
    it "should be a  PubmedSummary::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::PubmedSummary::Record)
    end
    it "should retrieve 5 articles" do
      expect(@bib.records.length).to eq(5)
    end
    it "author should include Gong, Li and Chen in first article" do
      %w{ Gong Chen Li}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "publication year should be correct" do
      n_authors=@bib.map {|b| b.year}
      expect(n_authors).to eq(["2015","2020","2017","2004","1981"])
    end

    it "numbers of authors should be [3,4,3,2,0]" do
      n_authors=@bib.map {|b| b.authors.count}
      expect(n_authors).to eq([3,4,3,2,0])
    end
    it "title for 5th article sshould be 'The beta-blocker heart attack trial. beta-Blocker Heart Attack Study Group.'" do
        expect(@bib[4].title).to eq("The beta-blocker heart attack trial. beta-Blocker Heart Attack Study Group.")
    end
    it "all doi  should be correct" do
      all_dois=@bib.map {|b| b.doi}
      expect(all_dois).to eq(["10.1371/journal.pone.0139442", "10.1111/jan.14210", "10.1089/jwh.2016.6156", nil, nil])
    end
    it "pubmed  should be correct" do
      all_pmid=@bib.map {|b| b.pubmed_id}
      expect(all_pmid).to eq(["26426421", "31566810", "28418750", "15455807", "7026815"])
    end

  end


  context "using Pubmed nbib with three articles in 2024" do
    before(:context) do
      @bib=BibliographicalImporter::PubmedSummary::Reader.parse( read_fixture("pubmed-depression-set.nbib") )
    end
    it "should be a  PubmedSummary::Record" do
      expect(@bib.records[0]).to be_instance_of(BibliographicalImporter::PubmedSummary::Record)
    end
    it "should retrieve 3 articles" do
      expect(@bib.records.length).to eq(3)
    end
    it "author should include Gong, Li and Chen in first article" do
      %w{Shen}.each do |author|
        expect(@bib[0].author).to include author
      end
    end
    it "publication year should be correct" do
      n_authors=@bib.map {|b| b.year}
      expect(n_authors).to eq(["2024","2024","2024"])
    end
    it "numbers of authors should be [1,14,5]" do
      n_authors=@bib.map {|b| b.authors.count}
      expect(n_authors).to eq([2,25,30])
    end
    it "title for 3th article should be 'Circulating myeloid-derived MMP8 in stress susceptibility and depression.'" do
      expect(@bib[2].title).to eq("Circulating myeloid-derived MMP8 in stress susceptibility and depression.")
    end
    it "all doi  should be correct" do
      all_dois=@bib.map {|b| b.doi}
      expect(all_dois).to eq(["10.1016/j.psychres.2023.115663","10.1016/j.cmet.2024.03.010","10.1038/s41586-023-07015-2"])
    end
    it "pubmed  should be correct" do
      all_pmid=@bib.map {|b| b.pubmed_id}
      expect(all_pmid).to eq(["38064908", "38582087", "38326622"])
    end

  end

end




