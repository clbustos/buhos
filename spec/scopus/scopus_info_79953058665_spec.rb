require_relative 'spec_helper'

describe "ARR parser of record 79953058665" do
  before {
    @xml=load_arr("SCOPUS_ID_79953058665.xml")
  }                                                       
  it "should include correct article information" do
    expect(@xml.title).to eq("The cohesion of intercorporate networks in France")
    expect(@xml.type_code).to eq("p")
    expect(@xml.type).to eq("conference proceeding".to_sym)
    expect(@xml.journal).to eq("Procedia - Social and Behavioral Sciences")
    expect(@xml.doi).to eq("10.1016/j.sbspro.2011.01.008")
    expect(@xml.volume).to eq("10")
    
    expect(@xml.book_title).to be_nil
  end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    
    expect(@xml.authors['16308896300'][:email]).to be_nil

  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords.length).to eq(8)
  end
  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(2)
    expect(@xml.subject_areas[0]).to eq({
        :abbrev=>"SOCI",
        :code=>3300,
        :name=>"Social Sciences (all)"
    })
    expect(@xml.subject_areas[1]).to eq({
        :abbrev=>"PSYC",
        :code=>3200,
        :name=>"Psychology (all)"
    })
    

  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations).to eq({
        "60009448"=>{
          :id=>"60009448",
        :name=>"Universite des Sciences et Technologies de Lille",
        :city=>"Villeneuve d'Ascq Cedex",
        :country=>"France",
          :type=>:scopus
        },
        "60027282"=>{
          :id=>"60027282",
          :name=>"Universidad Complutense de Madrid",
          :city=>"28223 Madrid",
          :country=>"Spain",
          :type=>:scopus
        }
    })
  end
end