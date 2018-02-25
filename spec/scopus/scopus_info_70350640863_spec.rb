require_relative 'spec_helper'

describe "ARR parser of record 70350640863" do
  before {
    @xml=load_arr("SCOPUS_ID_70350640863.xml")
    @first_afil="60016818"
    @empty_afil_name="Orientadora Escolar"
    @empty_afil_id="NS:381addbba7171767a4575a9d9a712ef2"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Personal self-regulation and perceived maladjusted school behaviors")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Psicothema")
    expect(@xml.volume).to eq("21")

    expect(@xml.book_title).to be_nil
  end

  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(3)
    expect(@xml.authors.keys).to eq(['35112634200','57189018111','55942293500'])

    expect(@xml.authors['35112634200'][:affiliation]).to eq(@first_afil)
    expect(@xml.authors['57189018111'][:affiliation]).to eq(@first_afil)
    expect(@xml.authors['55942293500'][:affiliation]).to eq(@empty_afil_id)
  end


  it "should include correct author groups" do
    # noinspection RubyResolve
    expect(@xml).to respond_to :author_groups
    expect(@xml.author_groups).to be_a Array
    expect(@xml.author_groups.length).to eq(2)
    expect(@xml.author_groups[0]).to eq({
                                            :authors => ['35112634200','57189018111'],
                                            :affiliation => '60016818'
                                        })
    expect(@xml.author_groups[1]).to eq({
                                            :authors => ['55942293500'],
                                            :affiliation =>@empty_afil_id
                                        })
  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)

    expect(@xml.affiliations[@first_afil]).to eq({
                                                     :id => @first_afil,
                                                     :name => "Universidad de Almeria",
                                                     :city => "Almeria",
                                                     :country => "Spain",
                                                     :type=>:scopus
                                                 })
    expect(@xml.affiliations[@empty_afil_id]).to eq({
                                                     :id => @empty_afil_id,
                                                     :name => @empty_afil_name,
                                                     :city => "",
                                                     :country => "NO_COUNTRY",
                                                     :type=>:non_scopus
                                                 })                                                 
  end
end
