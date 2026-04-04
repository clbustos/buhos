require_relative 'spec_helper'


describe 'Buhos extraction of data' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    #@temp=configure_complete_sqlite # TODO: REMOVE DEPENDENCE ON COMPLETE SQLITE
    @temp=configure_empty_sqlite
    #AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
    #                    :stage=>"review_full_text")

    sr_for_report
    CanonicalDocument.insert(:id=>2, :title=>"Better software required", :year=>2020)
    CanonicalDocument[1].update(:title=>"Better software required", :abstract=>"[RevMan]")
    SrField.insert(:systematic_review_id=>1, :order=>1, :name=>"stages", :description=>"Stages",
                   :type=>"textarea")
    SrField.insert(:systematic_review_id=>1, :order=>2, :name=>"features", :description=>"Features",
                   :type=>"textarea")
    SrField.insert(:systematic_review_id=>1, :order=>3, :name=>"tools", :description=>"Tools",
                   :type=>"textarea")

    SrField.update_table(SystematicReview[1])
    sr=SystematicReview[1]

        AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"screening_title_abstract")
        AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"review_full_text")
    $db[:analysis_sr_1].where(:user_id=>1, :canonical_document_id=>1).update(
                          :tools=>"[RevMan]",
                          :stages=>"[RevMan]",
                          :features=>"[RevMan]")
    login_admin

  end
  context 'when admin request form for a included document (1)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}
    it {expect(response_request).to be_ok}
    it {expect(response_request.body).to include "Better software required"}
    it {expect(response_request.body).to include "[RevMan]"}
  end

  context 'when enter information on form' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      put '/review/1/extract_information/cd/1/user/1/update_field', :pk=>'stages', :value=>'NEW VALUE'
    end
    let(:row_on_ds) {$db["SELECT * FROM analysis_sr_1 WHERE user_id=? AND canonical_document_id=?", 1, 1].first}
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}

    it {puts last_response.body; expect(last_response).to be_ok}
    it {expect(row_on_ds[:stages]).to eq("NEW VALUE")}
    it {expect(response_request.body).to include "NEW VALUE"}


  end


  context 'when admin request form for a not included document (2)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/2'; last_response}
    it {expect(response_request).to be_redirect}


  end

  context 'when request form response by not assigned user' do
    before(:each) do
      post '/login', :user=>'analyst', :password=>'analyst'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}
    it {expect(response_request).to_not be_ok}
    it {expect(response_request).to be_redirect}
  end



end