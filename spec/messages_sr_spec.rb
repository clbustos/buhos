require_relative 'spec_helper'


describe 'Systematic review messages:' do


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:id=>1,:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  context "when retrieve systematic review messages" do
    before(:context) do
      get '/review/1/messages'
    end
    it {expect(last_response).to be_ok}
  end

  context "when we post a review message" do
    before(:context) do
      post '/review/1/message/new', user_id:1 ,subject:'Test 1', text:'New text'
    end

    it {expect(last_response).to be_redirect}
    it "should add message on database" do
      expect(MessageSr.where(subject:'Test 1').count).to eq(1)
    end
    it "should be visible on messages page" do
      get '/review/1/messages'
      expect(last_response.body).to include('Test 1')
    end
  end


end


