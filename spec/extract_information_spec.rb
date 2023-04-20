require_relative 'spec_helper'


describe 'Buhos extraction of data' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite # TODO: REMOVE DEPENDENCE ON COMPLETE SQLITE
  end
  context 'when admin request form for a included document (40)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/40'; last_response}
    it {expect(response_request).to be_ok}
    it {expect(response_request.body).to include "Better software required"}
    it {expect(response_request.body).to include "[RevMan]"}
  end

  context 'when enter information on form' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      put '/review/1/extract_information/cd/40/user/1/update_field', :pk=>'stages', :value=>'NEW VALUE'
    end
    let(:row_on_ds) {$db["SELECT * FROM analysis_sr_1 WHERE user_id=? AND canonical_document_id=?", 1, 40].first}
    let(:response_request) {  get '/review/1/extract_information/cd/40'; last_response}

    it {puts last_response.body; expect(last_response).to be_ok}
    it {expect(row_on_ds[:stages]).to eq("NEW VALUE")}
    it {expect(response_request.body).to include "NEW VALUE"}


  end


  context 'when admin request form for a not included document (64)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/64'; last_response}
    it {expect(response_request).to be_redirect}


  end

  context 'when request form response by not assigned user' do
    before(:each) do
      post '/login', :user=>'analyst', :password=>'analyst'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/40'; last_response}
    it {expect(response_request).to_not be_ok}
    it {expect(response_request).to be_redirect}
  end



end