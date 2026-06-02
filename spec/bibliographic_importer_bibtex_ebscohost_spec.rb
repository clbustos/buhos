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
    it "uid should be id=2272c03f-3f9d-304d-99d7-a476025d7598" do
      expect(@bib[0].uid).to eq("id=2272c03f-3f9d-304d-99d7-a476025d7598")
    end
  end

  context "using Ebscohost without an id in the URL" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(<<~BIBTEX)
        @article{ebsco_without_id,
          title = {Record without provider id},
          author = {Doe, Jane},
          journal = {Example Journal},
          year = {2024},
          url = {https://research.ebsco.com/c/abc/search/details}
        }
      BIBTEX
    end

    it "should use the default record uid" do
      record=@bib.records[0]
      expect(record).to be_instance_of(BibliographicalImporter::BibTex::Record_Ebscohost)
      expect(record.uid).to eq(Digest::SHA256.hexdigest(record.bv.to_s))
    end
  end

  context "using Ebscohost using plink" do
    before(:context) do
      @bib=BibliographicalImporter::BibTex::Reader.parse(<<~BIBTEX)
        @article{19122106520260101,
 abstract  = "Considering the high prevalence of adolescent depression and anxiety, the profound functional consequences of untreated early psychosis and suicide being the number one cause of death in Australia among 15–19-year-olds, ensuring that teachers are literate about these disorders should be a high priority. Teachers' disorder-specific literacy is a pragmatic response to healthcare system constraints. This scoping review aimed to map the evidence of teacher mental health literacy training programs, specifically for depression, anxiety, early psychosis and suicide risk. PRISMA-ScR guidelines were followed. Included studies were published in English between 2000 and 2024, focused on teachers working with students in Year 7–12 and measured teachers' knowledge of depression, anxiety, psychosis or suicide risk. Studies were appraised for quality. Eighteen studies met the inclusion criteria. Nine evaluated knowledge of student depression, five evaluated knowledge of anxiety and five evaluated kn",
 author    = "Bowman, Siann and McKinstry, Carol and Howie, Linsey",
 number    = "1",
 title     = "Secondary School Teachers' Disorder-Specific Mental Health Literacy About Depression, Anxiety, Early Psychosis and Suicide Risk: A Scoping Review.",
 volume    = "16",
 url       = "https://research.ebsco.com/plink/979f049d-d748-33ed-93df-bc5c7bd511f8",
 year      = "2026",
 issn      = "2076-328X",
 journal   = "Behavioral Sciences (2076-328X)",
 keywords  = "Mental depression; Anxiety; Teenagers; Teachers; Psychoses; Suicide risk factors; Mental health education; Australia",
 pages     = "115-null",
 note      = "",
}
      BIBTEX
    end

    it "should use the default record uid" do
      record=@bib.records[0]
      expect(record).to be_instance_of(BibliographicalImporter::BibTex::Record_Ebscohost)
      expect(record.uid).to eq("979f049d-d748-33ed-93df-bc5c7bd511f8")
    end
  end
end
