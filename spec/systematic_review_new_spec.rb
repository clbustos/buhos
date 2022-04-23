require 'spec_helper'

describe 'Create a new systematic review using the web interface' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    User.insert(:id=>10, :login=>"user_without_group",
                :password=>Digest::SHA1.hexdigest("user_without_group"),
                :role_id=>"administrator",:active => 1)
  end

  context 'when admin user access to /review/new' do
    before(:context) do
      login_admin
      get "/review/new"
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should show correct title" do
      expect(last_response.body).to include(I18n::t(:Systematic_review_new))
    end

  end

  context 'when analyst user without permission access to /review/new' do
    before(:context) do
      login_analyst
      get "/review/new"
    end
    it "should status code will be not authorized" do
      expect(last_response.status).to eq(403)
    end

  end

  context 'when user with permission but without group access to /review/new' do
    before(:context) do
      post '/login', :user=>"user_without_group", :password=>"user_without_group"
      get "/review/new"
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
  end

end