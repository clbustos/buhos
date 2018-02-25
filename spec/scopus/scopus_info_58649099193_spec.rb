require_relative 'spec_helper'

describe "ARR parser of record 58649099193" do
  before {
    @xml=load_arr("SCOPUS_ID_58649099193.xml")
    @afil_islam="NS:#{Digest::MD5.hexdigest("Ibmec São Paulo||Brazil")}"
  }
  it "should include correct article information" do
    expect(@xml.title).to eq("Rituals in organizations: A review and expansion of current theory")
    expect(@xml.type_code).to eq("j")
    expect(@xml.type).to eq(:journal)
    expect(@xml.journal).to eq("Group and Organization Management")
    expect(@xml.volume).to eq("34")
    expect(@xml.cited_by_count).to eq(27)
    expect(@xml.book_title).to be_nil
    expect(@xml.doi).to eq("10.1177/1059601108329717")
    expect(@xml.eid).to eq("2-s2.0-58649099193")
  end

  it "should include correct authors" do

    expect(@xml.authors).to be_a Hash
    expect(@xml.authors.length).to eq(2)
    expect(@xml.authors['55890864500']).to eq({
                                                  :auid => "55890864500",
                                                  :seq => "1",
                                                  :initials => "G.",
                                                  :indexed_name => "Islam G.",
                                                  :surname => "Islam",
                                                  :given_name => "Gazi",
                                                  :email => "gislamster@gmail.com",
                                                  :affiliation => @afil_islam
                                              })
    expect(@xml.authors['8609618300']).to eq({
                                                 :auid => "8609618300",
                                                 :seq => "2",
                                                 :initials => "M.J.",
                                                 :indexed_name => "Zyphur M.",
                                                 :surname => "Zyphur",
                                                 :given_name => "Michael J.",
                                                 :email => nil,
                                                 :affiliation => "60016643"
                                             })
  end
  it "should include correct author keywords" do
    expect(@xml).to respond_to :author_keywords
    expect(@xml.author_keywords).to eq([
                                           "Organizational change", "Organizational culture", "Ritual", "Symbolic management"
                                       ])
  end

  it "should include correct subject areas" do
    expect(@xml).to respond_to :subject_areas
    expect(@xml.subject_areas).to be_a Array
    expect(@xml.subject_areas.length).to eq(2)
    expect(@xml.subject_areas[0]).to eq({
                                            :abbrev => "BUSI",
                                            :code => 1407,
                                            :name => "Organizational Behavior and Human Resource Management"
                                        })
    expect(@xml.subject_areas[1]).to eq({
                                            :abbrev => "PSYC",
                                            :code => 3202,
                                            :name => "Applied Psychology"
                                        })


  end
  it "should include correct author groups" do
    # noinspection RubyResolve
    expect(@xml).to respond_to :author_groups
    expect(@xml.author_groups).to be_a Array
    expect(@xml.author_groups.length).to eq(3)
    expect(@xml.author_groups[0]).to eq({
        :authors => ['55890864500'],
        :affiliation => @afil_islam
    })
    expect(@xml.author_groups[1]).to eq({
        :authors => ['8609618300'],
        :affiliation => "60016643"
    })
  end
  it "should include correct affiliation " do

    expect(@xml).to respond_to :affiliations
    expect(@xml.affiliations).to be_a Hash
    expect(@xml.affiliations.length).to eq(3)


    expect(@xml.affiliations["60016643"]).to eq({
                                                    :id => "60016643",
                                                    :name => "University of Washington-Bothell",
                                                    :city => "Bothell",
                                                    :country => "United States",
                                                    :type=>:scopus
                                                })
    expect(@xml.affiliations[@afil_islam]).to eq({

                                                     :id => @afil_islam,
                                                     :name => "Ibmec São Paulo",
                                                     :city => "",
                                                     :country => "Brazil",
                                                     :type=>:non_scopus

                                                 })


  end
end
