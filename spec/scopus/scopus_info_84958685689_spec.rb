require_relative 'spec_helper'

describe "ARR parser of record 84958685689" do
  before {
    @xml=load_arr("SCOPUS_ID_84958685689.xml")
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("The being in activity in leontiev's work and the social nature of psychism")
    expect(@xml.type).to eq(:book)
    expect(@xml.journal).to be_nil
    expect(@xml.cited_by_count).to eq(0)
    expect(@xml.book_title).to eq("Vygotsky and Leontiev: The Construction of a Marxist Psychology")
  end
  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['57127471200']).to eq({
        :auid=>"57127471200",
        :seq=>"1",
        :initials=>"R.L.d.",
        :indexed_name=>"Silva R.",
        :surname=>"Silva",
        :given_name=>"Rhayane Lourenço da",
        :email=>"rhayanelou@gmail.com.",
        :affiliation=>"60029498"
    })

  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq([
      "A. N. Leontiev","human activity", "Marxist psychology", "social nature of psyche"
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

  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(1)
    expect(@xml.affiliations).to eq({
        "60029498"=>{
          :id=>"60029498",
        :name=>"Universidade Estadual de Maringa",
        :city=>"Maringa",
        :country=>"Brazil",
          :type=>:scopus
        }
    })
  end
end