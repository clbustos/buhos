require 'spec_helper'
require_relative "../lib/bibliographical_importer/pmc_efetch_xml"
describe 'BibliographicalImporter::PmcEfetchXml' do
  before(:all) do
    @bib=BibliographicalImporter::PmcEfetchXml::Reader.parse(File.read("#{$base}/spec/fixtures/efetch_summary.xml"))
  end
  it "should retrieve 2 articles" do
    expect(@bib.records.length).to eq(2)
  end
  it "first article should have correct pubmed id" do
    expect(@bib[0].pubmed).to eq("23193287")
  end
  it "first article should have correct doi" do
    expect(@bib[0].doi).to eq("10.1093/nar/gks1195")
  end
  it "first article should have a not nil abstract" do
    expect(@bib[0].abstract).to_not be_nil
  end
  it "second article should have a not nil abstract" do
    expect(@bib[1].abstract).to be_nil
  end

  it "first article author should be 'Benson, Dennis A and Cavanaugh, Mark and Clark, Karen and Karsch-Mizrachi, Ilene and Lipman, David J and Ostell, James and Sayers, Eric W '" do
    expect(@bib[0].author).to eq("Benson, Dennis A and Cavanaugh, Mark and Clark, Karen and Karsch-Mizrachi, Ilene and Lipman, David J and Ostell, James and Sayers, Eric W")
  end
  it "first article should have correct title" do
    expect(@bib[0].title).to eq("GenBank.")
  end
  it "first article should have correct journal title" do
    expect(@bib[0].journal).to eq("Nucleic acids research")
  end

  it "second article author should be 'Hengartner, Michael P'" do
    expect(@bib[1].author).to eq("Hengartner, Michael P")
  end

end