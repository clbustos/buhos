require_relative 'spec_helper'


describe 'Personal messages:' do


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  context "when sending personal message by form" do
    before(:context) do
      post '/user/1/compose_message/send', {to:2, subject:'test subject', text:'test text'}
    end
    it "should redirect to user messages" do
      expect(last_response.header["Location"]).to eq("http://example.org/user/1/messages")
    end
    it "should be show on sender messages inbox" do
      get '/user/1/messages'
      expect(last_response.body).to include("test subject")
    end

    it "should be show on receiver messages inbox" do
      get '/user/2/messages'
      expect(last_response.body).to include("test subject")
    end
  end

  context "when mark personal message as read" do
    before(:context) do
      @subject="subject #{DateTime.now}"
      post '/user/1/compose_message/send', {to:2, subject:@subject, text:'test text 2'}
      mens=Message[subject:@subject]
      post "/message/#{mens[:id]}/seen_by/#{2}"
    end
    it {expect(last_response).to be_ok}
    it {expect(Message[subject:@subject].viewed).to be true}

  end


  context "when reply personal from other account" do
    before(:context) do
      post '/user/1/compose_message/send', {to:2, subject:'test subject 3', text:'test text 3'}
      mens=Message[subject:'test subject 3']
      post "/message_per/#{mens[:id]}/reply" , user_id:2, subject:"test reply", text:'test text reply'
    end
    it "should raise an 403 error" do
      expect(last_response.status).to eq(403)
    end
  end

  context "when reply personal messages" do
    before(:context) do
      post '/user/1/compose_message/send', {to:2, subject:'test subject 3', text:'test text 3'}
      mens=Message[subject:'test subject 3']
      post '/login', user:"analyst", password:'analyst'
      post "/message_per/#{mens[:id]}/reply" , user_id:2, subject:"test reply", text:'test text reply'
    end

    it "should redirect back" do
      expect(last_response).to be_redirect
    end
    it "should be show on sender user messages inbox" do
      login_admin
      get '/user/1/messages'
      expect(last_response.body).to include("test reply")
    end
  end


end


