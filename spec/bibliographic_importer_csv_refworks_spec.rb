require 'spec_helper'
require_relative "../lib/bibliographical_importer/csv"
describe 'BibliographicalImporter::CSV for RefWorks' do
  before(:all) do
    @bib=BibliographicalImporter::CSV::Reader.parse(File.read("#{$base}/spec/fixtures/refworks.csv"),'refworks')
  end
  it "should retrieve 97 articles" do
    expect(@bib.records.length).to eq(97)
  end
  it "first author should be 'Alby,Francesca and Zucchermaglio,Cristina and Fatigante,Marilena'" do
    expect(@bib[0].author).to eq("Alby,Francesca and Zucchermaglio,Cristina and Fatigante,Marilena")
  end

end