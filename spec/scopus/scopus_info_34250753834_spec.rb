require_relative 'spec_helper'

describe "ARR parser of record 34250753834" do
  before {
    @xml=load_arr("SCOPUS_ID_34250753834.xml")
    @aff_unique="NAFD:**NA**:ad1d256940b3837c32dbe299ec9cdf07"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Vygotsky and Sartre: Approaching methodological conceptions in the construction of psychological knowledge")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Psicologia e Sociedade")
    expect(@xml.cited_by_count).to eq(0)
    expect(@xml.book_title).to be_nil
    expect(@xml.eid).to eq("2-s2.0-34250753834")
  end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['16643262800']).to eq({:auid=>"16643262800", :seq=>"1", :initials=>"K.", :indexed_name=>"Maheirie K.", :given_name=>"Kátia", :surname=>"Maheirie", :email=>"maheirie@cfh.ufsc.br", :affiliation=>"60017609"})
    expect(@xml.authors['16642572500']).to eq({:auid=>"16642572500", :seq=>"2", :initials=>"K.B.", :indexed_name=>"França K.", :given_name=>"Kelly Bedin", :surname=>"França", :email=>nil, :affiliation=>"NAFD:**NA**:05327acf881feb684ff9f03093c57e76"})
  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq(["Historical-dialetical psychology", "Method", "Vygotsky and Sartre"])
  end

  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations).to eq({"60017609" => {:id=>"60017609", :name=>"Universidade Federal de Santa Catarina", :city=>"Florianopolis", :country=>"Brazil", :type=>:scopus},
                                     "NAFD:**NA**:05327acf881feb684ff9f03093c57e76" => {:id=>"NAFD:**NA**:05327acf881feb684ff9f03093c57e76", :name=>"SCOPUS_ID:34250753834|16642572500", :city=>"", :country=>"NO_COUNTRY", :type=>:non_scopus}})
  end
end
