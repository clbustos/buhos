require_relative 'spec_helper'


describe 'Systematic review messages:' do


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:id=>1,:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end

  def clear_all_messages
    MessageSr.where(systematic_review_id:1).delete
  end
  def post_message
    post '/review/1/message/new', user_id:1 ,subject:'Test 1', text:'New text'
  end
  context "when retrieve systematic review messages" do
    before(:context) do
      clear_all_messages
      get '/review/1/messages'
    end
    it {expect(last_response).to be_ok}
  end

  context "when we post a review message" do
    before(:context) do
      clear_all_messages
      post_message
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


  context "when we post a reply a message" do
    before(:context) do
      clear_all_messages
      post_message
      ms_id=MessageSr[subject:'Test 1'][:id]
      post "/message_sr/#{ms_id}/reply", user_id:1, subject:'reply', text:'reply text'
    end
    let(:original) {MessageSr[subject:'Test 1']}

    let(:reply) {MessageSr[subject:'reply']}
    it {expect(last_response).to be_redirect}
    it "should add message on database" do
      expect(reply[:id]).to be_truthy
    end
    it "should have reference to first message" do
      expect(reply[:reply_to]).to eq(original[:id])
    end
    it "should be visible on messages page" do
      get '/review/1/messages'
      expect(last_response.body).to include('reply')
    end
  end



end


