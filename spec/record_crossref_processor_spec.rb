require 'spec_helper'

describe 'Record crossref Processor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    Record[1].update(:uid=>"eid=2-s2.0-85032230905", :doi=>"10.1902/jop.2017.170238")
  end
  context "when record crossref processor is used on Record 1" do
    it "should process 38 records" do
      $log.info(Record[1])
      rcp=RecordCrossrefProcessor.new([Record[1]],$db)
      #$log.info(rcp)
      expect(rcp.result).to be_a(::Result)
      #$log.info(rcp.result.events[1][:message])
      expect(rcp.result.events[1][:message]).to include("38")
    end
  end
end