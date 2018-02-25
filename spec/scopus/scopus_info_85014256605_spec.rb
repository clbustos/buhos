require_relative 'spec_helper'

describe "ARR parser of record 85014256605" do
  before {
    @xml=load_arr("SCOPUS_ID_85014256605.xml")
    @aff_unique="NAFD:**NA**:ad1d256940b3837c32dbe299ec9cdf07"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Multiculturalism and citizenship in the United Kingdom: The case of female genital mutilation")
    expect(@xml.type).to eq(:book)
    expect(@xml.journal).to be_nil
    expect(@xml.cited_by_count).to eq(0)
    expect(@xml.book_title).to eq("Female Exiles in Twentieth and Twenty-First Century Europe")
	expect(@xml.doi).to eq("10.1057/9780230607262")
	expect(@xml.abstract).to be_nil  
end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash 
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['55936116600']).to eq({
        :auid=>"55936116600",
        :seq=>"1",
        :initials=>"A.",
        :indexed_name=>"Guiné A.",
        :surname=>"Guiné",
        :given_name=>"Anouk",
        :email=>nil,
        :affiliation=>@aff_unique
    })
expect(@xml.authors['57193491240']).to eq({
        :auid=>"57193491240",
        :seq=>"2",
        :initials=>"F.J.M.",
        :indexed_name=>"Fuentes F.",
        :surname=>"Fuentes",
        :given_name=>"Francisco Javier Moreno",
        :email=>nil,
        :affiliation=>"60001576"
    })
  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq([])
  end
  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(3)
    expect(@xml.subject_areas[0]).to eq({
        :abbrev=>"SOCI",
        :code=>3300,
        :name=>"Social Sciences (all)"
    })

  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations).to eq({
        
        "60001576"=>{
          :id=>"60001576",
        :name=>"Universitat de Barcelona",
        :city=>"Barcelona",
        :country=>"Spain",
          :type=>:scopus
        },@aff_unique=>{
          :id=>@aff_unique,
        :name=>"SCOPUS_ID:85014256605|55936116600",
        :city=>"",
        :country=>"NO_COUNTRY",
          :type=>:non_scopus
        }
    })
  end
end
