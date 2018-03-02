require 'spec_helper'

describe 'Record crossref Processor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  context "when record crossref processor is used on Record 1" do
    it "should process 38 records" do
      rcp=RecordCrossrefProcessor.new([Record[1]],$db)
      expect(rcp.result).to be_a(::Result)
      expect(rcp.result.events[1][:message]).to include("38")
    end
  end
end