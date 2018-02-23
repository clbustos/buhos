require 'rspec'
require_relative 'spec_helper'


require_relative("../installer")

describe 'When Buhos installer is activated' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixinInstaller  , :installer => :true}
  end

  it '/ should redirect to language selection', :installer=>true do
    get '/'
    expect(last_response).to be_redirect
    expect(last_response.body).to be_empty
  end
  it '/installer/select_language should be accesible', :installer=>true do
    get '/installer/select_language'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty

  end
  it '/installer/select_language should be change according to HTTP_ACCEPT_LANGUAGE', :installer=>true do
    request '/installer/select_language', 'HTTP_ACCEPT_LANGUAGE'=>'en'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Installer")
    request '/installer/select_language', 'HTTP_ACCEPT_LANGUAGE'=>'es'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
    expect(last_response.body).to include("Instalador")
  end

  it '/installer/basic_data_form should be accessible', :installer=>true do
    get '/installer/basic_data_form'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty

  end


end