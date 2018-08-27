require 'spec_helper'

describe 'Fulltext Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr
    @sr1=SystematicReview[1]
    @sr1.stage='report'
    SrField.insert(:id=>1, :systematic_review_id=>1, :order=>1, :name=>"field_1", :description=>"Field 1", :type=>"textarea")
    SrField.insert(:id=>2, :systematic_review_id=>1, :order=>2, :name=>"field_2", :description=>"Field 2", :type=>"select", :options=>"a=a;b=b")
    SrField.insert(:id=>3, :systematic_review_id=>1, :order=>3, :name=>"field_3", :description=>"Field 3", :type=>"multiple", :options=>"a=a;b=b")
    SrField.update_table(@sr1)
    CanonicalDocument.insert(:id=>1, :title=>"Title 1", :year=>0)
    create_search
    create_record(:cd_id=>1, :search_id=>1)
    $db[:analysis_sr_1].insert(:user_id=>1, :canonical_document_id=>1, :field_1=>"[campo1] [campo2]", :field_2=>"a",:field_3=>"a,b")

    Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1, :stage=>'review_full_text', :resolution=>'yes')
    ars=Analysis_SR_Stage.new(@sr1, 'report')
    #p @sr1.cd_id_by_stage(:report)
    #p ars.resolutions_by_cd
    #p ars.decisions_by_cd
    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/fulltext/html'
    end
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include name of review" do
      expect(last_response.body).to include("Test Systematic Review")
    end

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