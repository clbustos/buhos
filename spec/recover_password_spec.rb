require_relative 'spec_helper'
require 'mail'

describe 'Buhos recover password' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    User[login:'admin'].update(email:"test@test.com",
                               token_password:nil,
                               token_datetime:nil)

  end

  it "/forgotten_password should show a valid page" do
    get '/forgotten_password' , 'HTTP_ACCEPT_LANGUAGE'=>'en'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("password reset link")
  end
  context 'when requesting a password reset' do
    before do
      SecurityEvent.where{id>0}.delete
      Mail::TestMailer.deliveries.clear
      User[login:'admin'].update(token_password:nil, token_datetime:nil)
    end
    it "should redirect" do
      post '/forgotten_password' , email:'test@test.com'

      expect(last_response).to be_redirect
    end
    it "should create a security event" do
      post '/forgotten_password' , email:'test@test.com'
      expect(SecurityEvent.count).to eq(1)
    end
    it 'sends an email' do
      post '/forgotten_password', email:'test@test.com'
      expect(Mail::TestMailer.deliveries.length).to eq(1)
      expect(Mail::TestMailer.deliveries.first.to).to include('test@test.com')
    end
  end
  after(:all) do
    close_sqlite
  end

end
