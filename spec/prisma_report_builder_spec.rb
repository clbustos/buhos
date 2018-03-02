require 'spec_helper'

describe 'Prisma Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  context "when svg PRISMA flow diagram is downloaded" do
    before(:context) do
      get '/review/1/report/PRISMA/svg_download'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be image/svg+xml" do expect(last_response.header['Content-Type']).to eq('image/svg+xml') end
    it "should content dispostion be attachment and include .svg on name" do
      expect(last_response.header['Content-Disposition']).to include("attachment") and
          expect(last_response.header['Content-Disposition']).to include(".svg")
    end

  end

end