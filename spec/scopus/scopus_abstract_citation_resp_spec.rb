require_relative 'spec_helper'

describe "parser of an abstractCitationResponse object" do
  before {
    @xml1=load_arr("abstractCitationResp.xml")
    @xml2=load_arr("abstractCitationResp_2.xml")
    @xml10=load_arr("abstractCitationResp_10.xml")
    @xml100=load_arr("abstractCitationResp_100.xml")

    @connection=Scopus::Connection.new("fauxkey")
  }
  it "get correct URI for a request" do
    expect(@connection.get_uri_citation_overview([33847321982,34047259984], "2009-2016")).to eq("http://api.elsevier.com/content/abstract/citations?scopus_id=33847321982,34047259984&apiKey=fauxkey&date=2009-2016&field=h-index,dc:identifier,scopus_id,pcc,cc,lcc,rangeCount,rowTotal,sort-year,prevColumnHeading,columnHeading,laterColumnHeading,prevColumnTotal,columnTotal,laterColumnTotal,rangeColumnTotal,grandTotal")
  end
  it "should include correct raw information" do
    expect(@xml1.h_index).to eq(1)
    expect(@xml2.h_index).to eq(2)
    expect(@xml10.h_index).to eq(2)

    expect(@xml1.year_range).to eq(2011.upto(2013).to_a)
    expect(@xml2.year_range).to eq(2009.upto(2016).to_a)
    expect(@xml100.year_range).to eq(2007.upto(2017).to_a)

    expect(@xml1.prev_total).to eq(54)
    expect(@xml1.column_total).to eq([3,1,5])
    expect(@xml1.later_total).to eq(0)

    expect(@xml1.range_total).to eq(9)
    expect(@xml1.grand_total).to eq(63)




    expect(@xml2.prev_total).to eq(9)
    expect(@xml2.later_total).to eq(0)
    expect(@xml2.column_total).to eq([9,8,7,3,6,8,2,1])

    expect(@xml2.range_total).to eq(44)
    expect(@xml2.grand_total).to eq(53)


    expect(@xml1.records).to eq([{:scopus_id=>"SCOPUS_ID:0033001756", :pcc=>54, :lcc=>0, :cc=>[3, 1, 5]}])
    expect(@xml2.records).to eq([{:scopus_id=>"SCOPUS_ID:34047259984", :pcc=>3, :lcc=>0, :cc=>[6, 4, 2, 1, 2, 7, 0, 0]}, {:scopus_id=>"SCOPUS_ID:33847321982", :pcc=>6, :lcc=>0, :cc=>[3, 4, 5, 2, 4, 1, 2, 1]}])

  end
  it "should return correct processed information" do
    expect(@xml1.n_records).to eq(1)
    expect(@xml2.n_records).to eq(2)
    expect(@xml10.n_records).to eq(10)
    expect(@xml100.n_records).to eq(200)
    expect(@xml1.scopus_id_a).to eq(["SCOPUS_ID:0033001756"])
    expect(@xml2.scopus_id_a).to eq(["SCOPUS_ID:34047259984","SCOPUS_ID:33847321982"])
    expect(@xml10.scopus_id_a).to eq(["SCOPUS_ID:84939124377","SCOPUS_ID:84938769733","SCOPUS_ID:84938770947","SCOPUS_ID:84938802206","SCOPUS_ID:84938818292","SCOPUS_ID:84934344109","SCOPUS_ID:84947285680","SCOPUS_ID:85009771927","SCOPUS_ID:84945959419","SCOPUS_ID:84943666241"])
    expect(@xml1.citations_by_year("SCOPUS_ID:0033001756")).to eq({2011=>3,2012=>1,2013=>5})
    expect(@xml2.citations_by_year("SCOPUS_ID:34047259984")).to eq({2009=>6,2010=>4,2011=>2,2012=>1,2013=>2,2014=>7,2015=>0,2016=>0})

    expect(@xml100.citations_by_year("SCOPUS_ID:84866769122")).to eq(nil)
    expect(@xml1.citations_outside_range?("SCOPUS_ID:0033001756")).to eq(true)
    expect(@xml2.citations_outside_range?("SCOPUS_ID:34047259984")).to eq(true)

    expect(@xml100.empty_record?("SCOPUS_ID:84866769122")).to eq(true)
  end

end
