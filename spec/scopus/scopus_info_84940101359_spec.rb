require_relative 'spec_helper'

describe "ARR parser of record 84940101359" do
  before {
    @xml=load_arr("SCOPUS_ID_84940101359.xml")
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Psychometric properties of an innovative self-report measure: The social anxiety questionnaire for adults")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Psychological Assessment")
    expect(@xml.doi).to eq("10.1037/a0038828")
  end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(114)
    #require 'pp'
    #pp @xml.affiliations
  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq(["Cross-cultural research", "SAQ", "Self-report assessment", "Social anxiety", "Social phobia"])
  end
  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(2)
    expect(@xml.subject_areas[1]).to eq({
                                            :abbrev => "PSYC",
                                            :code => 3203,
                                            :name => "Clinical Psychology"
                                        })

  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    
    
    expect(@xml.affiliations.length).to eq(22)
    
    # First one will be a common affiliation
    expect(@xml.affiliations["60019674"]).to eq({ :id => "60019674",
                                                  :name => "Boston University",
                                                  :city => "Boston",
                                                  :country => "United States",
                                                  :type=>:scopus
                                                })
    expect(@xml.affiliations["NS:52b6563f94d13404d8dad776b7e7087f"]).to eq({
        :id=>"NS:52b6563f94d13404d8dad776b7e7087f",
        :name => "FUNVECA Clinical Psychology Center",
        :city => "Granada",
        :country => "Spain",
        :type=>:non_scopus
                                                                           }
                                                                        )

  end
end
