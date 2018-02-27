require_relative 'spec_helper'


describe 'Messages' do


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    Revision_Sistematica.insert(:nombre=>'Test Review', :grupo_id=>1, :administrador_revision=>1)
    login_admin
  end
  context "when sending personal message by form" do
    before(:context) do
      post '/user/1/compose_message/send', {to:2, asunto:'test subject', texto:'test text'}
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
      @asunto="asunto #{DateTime.now}"
      post '/user/1/compose_message/send', {to:2, asunto:@asunto, texto:'test text 2'}
      mens=Mensaje[asunto:@asunto]
      post "/message/#{mens[:id]}/seen_by/#{2}"
    end
    it {expect(last_response).to be_ok}
    it {expect(Mensaje[asunto:@asunto].visto).to be true}

  end
  context "when reply personal messages" do
    before(:context) do
      post '/user/1/compose_message/send', {to:2, asunto:'test subject 3', texto:'test text 3'}
      mens=Mensaje[asunto:'test subject 3']
      post "/message_per/#{mens[:id]}/reply" , user_id:2, asunto:"test reply", texto:'test text reply'
    end

    it "should redirect back" do
      expect(last_response).to be_redirect
    end
    it "should be show on sender user messages inbox" do
      get '/user/1/messages'
      $log.info(Mensaje.all)
      expect(last_response.body).to include("test reply")
    end
  end



end


