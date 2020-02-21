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
      post '/group/update', group_id:"NA", :name=>'New group', :description=>'description', group_administrator:1, users:{1=>true,2=>true}
    end
    let(:group){Group[name:'New group']}
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
      @group_id=Group.insert(:name=>'New group 2', :description=>'description', group_administrator:1)
      get "/group/#{@group_id}/delete"
    end

    it "should response be redirect" do
      expect(last_response).to be_redirect
    end

    it "shoud delete object" do
      expect(Group[@group_id]).to be_falsey
    end
  end

  context "when user is made active" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      rule=Role.limit(1).first

      @user_id = User.insert(login:"user_2", name:"User 2", active:false, password:'111', role_id:rule[:id])
      post '/admin/users/update', user:[@user_id], action:'active'
    end
    it "should be active" do
      expect(User[@user_id][:active]).to be_truthy
    end
    after(:context) do
      User[@user_id].delete
    end
  end

  context "when user is made inactive" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      rule=Role.limit(1).first

      @user_id = User.insert(login:"user_2", name:"User 2", active:true, password:'111', role_id:rule[:id])
      post '/admin/users/update', user:[@user_id], action:'inactive'
    end
    it "should be active" do
      expect(User[@user_id][:active]).to be_falsey
    end
    after(:context) do
      User[@user_id].delete
    end
  end

  context "when users are deleted" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      rule=Role.limit(1).first

      @user_1 = User.insert(login:"user_2", name:"User 2", active:true, password:'111', role_id:rule[:id])
      @user_2 = User.insert(login:"user_3", name:"User 3", active:true, password:'111', role_id:rule[:id])
      post '/admin/users/delete', users:"#{@user_1},#{@user_2}", action:'delete'
    end

    it "should delete users" do
      expect(User.where(id: [@user_1, @user_2]).count).to eq(0)
    end
    after(:context) do
      User.where(id: [@user_1, @user_2]).delete
    end
  end



  after(:all) do
    @temp=nil
    close_sqlite
  end


end