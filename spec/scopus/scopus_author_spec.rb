require_relative 'spec_helper'

describe "parser of an authorRetrievalResponse object" do
  before {
    @xml1=load_arr("AUTHOR_ID_25634855600.xml")
    @xml2=load_arr("AUTHOR_2.xml")

    @connection=Scopus::Connection.new("fauxkey")
  }
  it "get correct URI for a request" do
    expect(@connection.get_uri_author(25634855600)).to eq("https://api.elsevier.com/content/author?author_id=25634855600&apiKey=fauxkey&view=LIGHT")
  end
  it "should include correct raw information" do
  pending
    expect(@xml1).to be < Scopus::XMLResponse::Authorretrievalresponse
    expect(@xml2).to be < Authorretrievalresponselist
  end

end
