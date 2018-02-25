require_relative 'spec_helper'

describe "ARR parser of record 75249099053" do
  before {
    @xml=load_arr("SCOPUS_ID_75249099053.xml")
  }                                                       
  it "should include correct article information" do
    expect(@xml.title).to eq("Psychosocial impact of information and communication technologies (ICT): Technostress, physical damage and professional satisfaction")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Acta Colombiana de Psicologia")
    expect(@xml.volume).to eq("11")
    
    expect(@xml.book_title).to be_nil
  end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['27067906600']).to eq({
        :auid=>"27067906600",
        :seq=>"1",
        :initials=>"M.",
        :indexed_name=>"Dias Pocinho M.",
        :surname=>"Dias Pocinho",
        :given_name=>"Margarida",
        :email=>"mpocinho@uma.pt",
        :affiliation=>"60016979"
    })

  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq([
      "Ict","Professional satisfaction","Psychosocial impact","Techno-stress"
      ])
  end
  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(2)
    expect(@xml.subject_areas[0]).to eq({
        :abbrev=>"PSYC",
        :code=>3200,
        :name=>"Psychology (all)"
    })
    expect(@xml.subject_areas[1]).to eq({
        :abbrev=>"MEDI",
        :code=>2738,
        :name=>"Psychiatry and Mental Health"
    })
    

  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations).to eq({
        "108227642"=>{
          :id=>"108227642",
        :name=>"Secretaria Regional de EducaçÃo da Madeira",
        :city=>"",
        :country=>"Portugal",
          :type=>:scopus
        },
        "60016979"=>{
          :id=>"60016979",
          :name=>"Universidade da Madeira",
          :city=>"Funchal",
          :country=>"Portugal",
          :type=>:scopus
        }
    })
  end
end