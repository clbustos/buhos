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

  context "when accessing JSON group information" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
    end

    let(:response) {get '/group/1/datos.json'}
    it "responds successfully" do
      expect(response).to be_ok
    end
    it "can be parsed as JSON" do
      expect {JSON.parse(response.body)}.not_to raise_error
    end
    it "contains 5 keys in the JSON response" do
      expect(JSON.parse(response.body).keys.sort).to eq(["description", "group_administrator", "id", "name", "users"])
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