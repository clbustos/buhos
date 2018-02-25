require_relative 'spec_helper'

describe "ARR parser of record 84937792319" do
  before {
    @xml=load_arr("SCOPUS_ID_84937792319.xml")
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("There's more than one way to conduct a replication study: Beyond statistical significance")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Psychological Methods")
    expect(@xml.cited_by_count).to eq(9)
    expect(@xml.book_title).to be_nil
    expect(@xml.eid).to eq("2-s2.0-84937792319")
    expect(@xml.abstract).to include("As the field of psychology")
  end
end
