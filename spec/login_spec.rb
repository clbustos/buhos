require 'rspec'
require 'sinatra'
require_relative 'spec_helper'


describe 'Sinatra APP login' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_test_sqlite
    require_relative("../app")
  end

  it "/login should show a valid page" do
    get '/' , 'HTTP_ACCEPT_LANGUAGE'=>'en'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Password")
  end

  it "Incorrect login redirect to login page" do
    post '/login' , :user=>'noone', :password=>'noone'
    expect(last_response).to_not be_ok
    expect(last_response.body).to be_empty
    expect(last_response.header["Location"]).to eq("http://example.org/login")
  end

  it "Correct login redirect to main page" do
    post '/login' , :user=>'admin', :password=>'admin'
    expect(last_response).to_not be_ok
    expect(last_response.body).to be_empty
    expect(last_response.header["Location"]).to eq("http://example.org/")
  end

  it "Correct login redirect to main page and show dashboard" do
    post '/login' , :user=>'admin', :password=>'admin'
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include ("Dashboard")
  end


  after(:all) do
    close_sqlite
  end

end