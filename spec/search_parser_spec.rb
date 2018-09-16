require 'rspec'
require_relative("../lib/buhos/search_parser")
describe 'SearchParser' do
  it "should parse a simple query without error" do
    parser=Buhos::SearchParser.new
    expect {parser.parse(" author( w1 OR w2) title(\"dd\")")}.not_to raise_error
  end
  it "should raise an expection on incorrect query" do
    parser=Buhos::SearchParser.new
    expect {parser.parse(" author( w1 OR w2 title(\"dd\")")}.to raise_exception(Buhos::SearchParser::ParsingError)
  end

  it ".to_sql should include both clausules by AND by default" do
    parser=Buhos::SearchParser.new
    parser.parse(" author( a1 a2)")
    expect(parser.to_sql).to include("INSTR(author, 'a1')>0")
    expect(parser.to_sql).to include("INSTR(author, 'a2')>0")
    expect(parser.to_sql).to match(/INSTR\(author, 'a1'\)>0.+AND.+INSTR\(author, 'a2'\)>0/)

  end

  it ".to_sql should include both clausules by OR using or: option" do
    parser=Buhos::SearchParser.new
    parser.parse(" author(a1) author(a2)")
    expect(parser.to_sql(or_union: true)).to match(/INSTR\(author, 'a1'\)>0.+OR.+INSTR\(author, 'a2'\)>0/)

  end


end