require_relative 'spec_helper'


require_relative("../installer")

describe "Buhos installer" do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixinInstaller  , :installer => :true}
  end


  context 'when access /', :installer=>true do
    let(:response) {get '/'}
    it 'redirects', :installer=>true  do
      expect(response).to be_redirect
    end
    it 'with no body',  :installer=>true   do
      expect(response.body).to be_empty
    end
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

  context "when /installer/select_language form is sended", :installer=>true do
    it "should change locale to es if params['language'] is es" do
      post('/installer/select_language', language:'es')
      expect(::I18n.locale).to eq(:es)
    end
    it "should change locale to es if params['language'] is en" do
      post('/installer/select_language', language:'en')
      expect(::I18n.locale).to eq(:en)
    end
    it "should raise error if params['language'] is unknown" do
      expect {post('/installer/select_language', language:'unknown')}.to raise_error(I18n::InvalidLocale)

    end

  end
  it '/installer/basic_data_form should be accessible', :installer=>true do
    get '/installer/basic_data_form'
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty

  end

  context 'when basic_data_form is send', :installer=>true do
    form_post={
        db_adapter:     'mysql2',
        db_hostname:    'example.5000m',
        db_port:        '5000',
        db_username:    'other_user',
        db_password:    'other_password',
        db_database:    'other_database',
        db_filename:    '',
        proxy_hostname: 'proxy.example.com',
        proxy_port:     '3000',
        proxy_user:     'proxy_user',
        proxy_password: 'proxy_pass',
        scopus_key:     'scopus_key'
    }

    let(:dot_env) {Tempfile.new}
    let(:response) {

      ENV['DOT_ENV']=dot_env.path
      post('/installer/basic_data_form',form_post)
    }

    it 'should return correct status and redirect' do
      expect(response.status).to eq(302)
      expect(response.header["Location"]).to eq("http://example.org/installer/populate_database")
    end
    it "should create correct env file  for mysql" do
      response
      env_content=dot_env.read
      expect(env_content).to eq("DATABASE_URL=mysql2://other_user:other_password@example.5000m:5000/other_database
PROXY_HOSTNAME=proxy.example.com
PROXY_PORT=3000
PROXY_USER=proxy_user
PROXY_PASSWORD=proxy_pass
SCOPUS_KEY=scopus_key\n")

    end
  end

  context 'when only sqlite data is send', :installer=>true do
    form_post={
        db_adapter:     'sqlite',
        db_hostname:    '',
        db_port:        '',
        db_username:    '',
        db_password:    '',
        db_database:    '',
        db_filename:    'db_test.sqlite',
        proxy_hostname: '',
        proxy_port:     '',
        proxy_user:     '',
        proxy_password: '',
        scopus_key:     ''
    }

    let(:dot_env) {Tempfile.new}
    let(:response) {

      ENV['DOT_ENV']=dot_env.path
      post('/installer/basic_data_form',form_post)
    }

    it 'should return correct status and redirect' do
      expect(response.status).to eq(302)
      expect(response.header["Location"]).to eq("http://example.org/installer/populate_database")
    end
    it "should create correct env file  for mysql" do
      response
      env_content=dot_env.read
      expect(env_content).to eq("DATABASE_URL=sqlite://db_test.sqlite\n")

    end
  end



end