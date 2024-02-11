require_relative 'spec_helper'
require 'sinatra'

describe 'Buhos administration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
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



  context "when a new group is created correctly" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', group_id:"NA", :name=>'New group',
           :description=>'description', group_administrator:1, users:{1=>true,2=>true}
    end
    let(:group){Group[name:'New group']}
    it "redirects the response" do
      expect(last_response).to be_redirect
    end
    it "creates a new group object" do
      expect(group).to be_truthy
    end
    it "assigns the correct name to the group" do
      expect(group[:name]).to eq('New group')
    end
  end

  context "when a new group is created without name" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', group_id:"NA", :name=>'', :description=>'d2', group_administrator:1,
           users:{1=>true,2=>true}
    end
    let(:group_attempt) { Group[description: 'd2'] }
    it "does not create a new group" do
      expect(group_attempt).to be_nil
    end


    it "redirects to the creation page" do
      expect(last_response).to be_redirect
    end
  end

  context "when a new group is created without description" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', group_id:"NA", :name=>'n3', :description=>'', group_administrator:1,
           users:{1=>true,2=>true}
    end
    let(:group_attempt) { Group[name: 'n3'] }
    it "does not create a new group" do
      expect(group_attempt).to be_nil
    end
    it "redirects to the creation page" do
      expect(last_response).to be_redirect
    end
  end
  context "when a new group is created without any user" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', group_id:"NA", :name=>'n4', :description=>'d3', group_administrator:1,
           users:{}
    end
    let(:group_attempt) { Group[name: 'n4'] }
    it "does not create a new group" do
      expect(group_attempt).to be_nil
    end
    it "redirects to the creation page" do
      expect(last_response).to be_redirect
    end
  end
  context "when a new group is created not considering the admin as member" do
    before(:context) do
      post '/login' , :user=>'admin', :password=>'admin'
      post '/group/update', group_id:"NA", :name=>'New group 2', :description=>'description', group_administrator:1,
           users:{2=>true}
    end
    let(:group_attempt) { Group[name: 'New group 2'] }
    it "does not create a new group" do
      expect(group_attempt).to be_nil
    end

    it "redirects to the creation page" do
      expect(last_response).to be_redirect

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


  after(:all) do
    @temp=nil
    close_sqlite
  end


end