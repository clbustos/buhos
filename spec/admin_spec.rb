require_relative 'spec_helper'
require 'sinatra'



describe 'Buhos administration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
  end


  context "when analyst try to access admin pages" do
    before(:each) do
      post '/login' , :user=>'analyst', :password=>'analyst'
    end

    it{expect('/admin/groups').to be_prohibited}
    it{expect('/group/new').to be_prohibited}
    it{expect('/role/new').to be_prohibited}
    it{expect('/admin/users').to be_prohibited}
    it{expect('/user/new').to be_prohibited}
    it{expect('/role/new').to be_prohibited}
  end

  context "when admin try to access admin pages" do
    let(:login) {post '/login' , :user=>'admin', :password=>'admin'}
    it  {expect('/admin/groups').to be_available_for_admin}
    it  {expect('/admin/roles').to be_available_for_admin}
    it {expect('/group/new').to be_available_for_admin}
    it {expect('/admin/users').to be_available_for_admin}
    it {expect('/user/new').to be_available_for_admin}
    it {expect('/role/new').to be_available_for_admin}

  end
  context "when group edit view is acceded" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
    end

    let(:response) {get '/group/1/edit'}
    it "response should be ok" do
      expect(response).to be_ok
    end
  end

  context "when json group information is acceded,response" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
    end

    let(:response) {get '/group/1/datos.json'}
    it "should be ok" do
      expect(response).to be_ok
    end
    it "should be parsed as JSON" do
      expect {JSON.parse(response.body)}.not_to raise_error
    end
    it "should JSON have 5 keys" do
      expect(JSON.parse(response.body).keys.sort).to eq(["description", "group_administrator", "id", "name", "users"])
    end

  end

  context "when new group is created" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', grupo_id:"NA", :name=>'New group', :description=>'description', administrador_grupo:1, usuarios:{1=>true,2=>true}
    end
    let(:group){Grupo[name:'New group']}
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should create a new group object" do
      expect(group).to be_truthy
    end
    it "should have correct name" do
      expect(group[:name]).to eq('New group')
    end
  end


  context "when group is deleted" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      @group_id=Grupo.insert(:name=>'New group 2', :description=>'description', administrador_grupo:1)
      get "/group/#{@group_id}/delete"
    end
    it "should response be redirect" do
      #$log.info(last_response.body)
      expect(last_response).to be_redirect
    end
    it "shoud delete object" do
      expect(Grupo[@group_id]).to be_falsey
    end
  end


  after(:all) do
    @temp=nil
    close_sqlite
  end

end