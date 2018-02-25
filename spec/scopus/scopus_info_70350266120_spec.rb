require_relative 'spec_helper'

describe "ARR parser of record 70350266120" do
  before {
    @xml=load_arr("SCOPUS_ID_70350266120.xml")
    @first_afil="NS:1b8a8f817aae00664581eec100fda96b"
    @second_afil="NS:ff229c47451b763a6a3b47e3beb37d4f"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Invention and direction in a therapeutic workshop at a daytime outpatient clinic")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Revista Latinoamericana de Psicopatologia Fundamental")
    expect(@xml.volume).to eq("12")

    expect(@xml.book_title).to be_nil
  end

  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['35101796900'][:email]).to eq("sthiagofranco@yahoo.com.br")
    expect(@xml.authors['35101796900'][:affiliation]).to eq(@first_afil)
    expect(@xml.authors['35101403400'][:affiliation]).to eq(@second_afil)
  end

  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(2)
    expect(@xml.subject_areas[0]).to eq({
                                            :abbrev => "PSYC",
                                            :code => 3203,
                                            :name => "Clinical Psychology"
                                        })
    expect(@xml.subject_areas[1]).to eq({
                                            :abbrev => "MEDI",
                                            :code => 2738,
                                            :name => "Psychiatry and Mental Health"
                                        })



  end
  it "should include correct author groups" do
    # noinspection RubyResolve
    expect(@xml).to respond_to :author_groups
    expect(@xml.author_groups).to be_a Array
    expect(@xml.author_groups.length).to eq(2)
    expect(@xml.author_groups[0]).to eq({
        :authors => ['35101796900'],
        :affiliation => @first_afil
    })
    expect(@xml.author_groups[1]).to eq({
        :authors => ['35101403400'],
        :affiliation => @second_afil
    })
  end
  it "should include correct affiliation " do
    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)
    expect(@xml.affiliations[@first_afil]).to eq({
                                                    :id => @first_afil,
                                                    :name => "Rua Ribeiro de Almeida, 2/ap.4 - Laranjeiras",
                                                    :city => "22240-060 Rio de Janeiro, RJ",
                                                    :country => "Brazil",
                                                    :type=>:non_scopus
                                                })
    expect(@xml.affiliations[@second_afil]).to eq({

                                                     :id => @second_afil,
                                                     :name => "Rua Fonte da Saudade, 256/401",
                                                     :city => "Lagoa 22471-210 Rio de Janeiro, RJ",
                                                     :country => "Brazil",
                                                     :type=>:non_scopus

                                                 })


  end
end