require_relative 'spec_helper'


describe 'Buhos login' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    User[1].update(email:"admin@test.com")
  end

  it "/login should show a valid page" do
    get '/' , 'HTTP_ACCEPT_LANGUAGE'=>'en'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Password")
  end
  it "/login should change according to HTTP_ACCEPT_LANGUAGE" do
    get 'logout'
    #$log.info("Trato es")
    request '/' , 'HTTP_ACCEPT_LANGUAGE'=>'es'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Revisiones")
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

  it "Correct login using login name redirect to main page and show dashboard" do
    post '/login' , :user=>'admin', :password=>'admin'
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Dashboard")
  end

  it "Correct login using e-mail redirect to main page and show dashboard" do
    post '/login' , :user=>'admin@test.com', :password=>'admin'
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Dashboard")
  end

  after(:all) do
    close_sqlite
  end

end