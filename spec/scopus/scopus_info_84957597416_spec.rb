require_relative 'spec_helper'

describe "ARR parser of record 84957597416" do
  before {
    @xml=load_arr("SCOPUS_ID_84957597416.xml")
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Blocking in Humans: Logical Reasoning Versus Contingency Learning")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Psychological Record")
    expect(@xml.volume).to eq("66")

    expect(@xml.book_title).to be_nil
  end

  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(1)
    expect(@xml.authors.keys).to eq(['45560977800'])
    expect(@xml.authors['45560977800'][:affiliation]).to eq(['60105245','100310534'])
  end


  it "should include correct author groups" do
    # noinspection RubyResolve
    expect(@xml).to respond_to :author_groups
    expect(@xml.author_groups).to be_a Array
    expect(@xml.author_groups.length).to eq(2)
    expect(@xml.author_groups[0]).to eq({
                                            :authors => ['45560977800'],
                                            :affiliation => '60105245'
                                        })
    expect(@xml.author_groups[1]).to eq({
                                            :authors => ['45560977800'],
                                            :affiliation =>'100310534'
                                        })
  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations['60105245']).to eq({
                                                     :id => '60105245',
                                                     :name => "Fundacion Universitaria Konrad Lorenz",
                                                     :city => "Bogota",
                                                     :country => "Colombia",
                                                     :type=>:scopus
                                                 })
  end
end