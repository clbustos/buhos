require 'spec_helper'

describe 'Fulltext Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/fulltext/excel_download'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be correct mimetype" do expect(last_response.header['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') end
    it "should content dispostion be attachment and include .xlsx on name" do
      expect(last_response.header['Content-Disposition']).to include("attachment") and
          expect(last_response.header['Content-Disposition']).to include(".xlsx")
    end

  end

end