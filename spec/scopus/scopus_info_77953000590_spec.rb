require_relative 'spec_helper'

describe "ARR parser of record 77953000590" do
  before {
    @xml=load_arr("SCOPUS_ID_77953000590.xml")
    @afil_1="108788134"
    @afil_2="NS:f040cf0898fec7692e3b1a2e3d1aa823"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("A new protocol test for physical activity research in obese children (Etiobe Project)")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Annual Review of CyberTherapy and Telemedicine")
    expect(@xml.volume).to eq("7")
    expect(@xml.eid).to eq("2-s2.0-77953000590")
expect(@xml.abstract).to include("A new protocol is presented")
    expect(@xml.book_title).to be_nil
  end

  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(5)
    expect(@xml.authors['26423690300'][:affiliation]).to eq(@afil_1)
    expect(@xml.authors['36088831800'][:affiliation]).to eq(@afil_2)
  end
  
  
  it "should include correct author groups" do
    # noinspection RubyResolve
    expect(@xml).to respond_to :author_groups
    expect(@xml.author_groups).to be_a Array
    expect(@xml.author_groups.length).to eq(2)
    expect(@xml.author_groups[0]).to eq({
        :authors => ["26423690300", "18937989500", "7003335420", "35217871400"],
        :affiliation => @afil_1
    })
    expect(@xml.author_groups[1]).to eq({
        :authors => ["18937989500", "7003335420", "36088831800"],
        :affiliation => @afil_2
    })
  end
  it "should include correct affiliation " do

    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(2)


    expect(@xml.affiliations[@afil_1]).to eq({
                                                    :id => @afil_1,
                                                    :name => "Institute of Research and Innovation on Bioengineering for Human Beings I3BH",
                                                    :city => "",
                                                    :country => "Spain",
                                                    :type=>:scopus
                                                })
    expect(@xml.affiliations[@afil_2]).to eq({

                                                     :id => @afil_2,
                                                     :name => "CIBER de Fisiopatología de la Obesidad y Nutrición (CIBEROBN)",
                                                     :city => "",
                                                     :country => "Spain",
                                                     :type=>:non_scopus

                                                 })


  end
end
