require 'spec_helper'

describe 'User resources:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
  end

  context "when editing user data as admin, changing user role to guest" do
    before(:context) do
      login_admin
      User[2].update(:role_id=>'analyst')
      put "/user/edit/role_id", :pk=>2, :value=>'guest'
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should change user role to guest" do
      expect(User[2].role_id).to eq('guest')
    end
  end

  context "when I edit a user with an existing login" do
    before(:context) do
      login_admin
      User.where(:id=>3).update(:login=>'guest')
      User[2].update(:login=>'analyst')
      put "/user/edit/login", :pk=>2, :value=>'guest'
    end
    it "should response be not ok" do
      expect(last_response).to_not be_ok
    end
    it "should not change login" do
      expect(User[2].login).to eq('analyst')
    end
  end

  context "when I edit a user with the role of analyst, changing to guest" do
    before(:context) do
      login_analyst
      User[2].update(:role_id=>'analyst')
      put "/user/edit/role_id", :pk=>2, :value=>'guest'
    end
    it "should response be not ok" do
      expect(last_response).to_not be_ok
    end
    it "should maintain the user role to analyst" do
      expect(User[2].role_id).to eq('analyst')
    end
  end

  context "when changing a password as admin" do
    before(:context) do
      login_admin
      post '/user/2/change_password', :password=>'dos1', :repeat_password=>'dos1'
    end
    it "should response be redirect" do
      expect(last_response).to be_redirect
    end

    it "should password be changed" do
      expect( User[2].correct_password?('dos1')).to be true
    end

    after(:context) do
      User[2].change_password("analyst")
    end

  end

  context "when changing a password as admin with incorrect repeat" do
    before(:context) do
      login_admin
      post '/user/2/change_password', :password=>'dos1', :repeat_password=>'dos2'
    end
    it "should response be_redirect" do
      expect(last_response).to be_redirect
    end

    it "should password not be changed" do
      expect( User[2].correct_password?('dos1')).to be false
    end

    after(:context) do
      User[2].change_password("analyst")
    end


  end


  context "when changing own language as analyst" do
    before(:context) do
      login_analyst
      User[2].update(:language=>'en')
      put "/user/edit/language", :pk=>2, :value=>'es'

    end
    it "should response be redirect" do
      expect(last_response).to be_ok
    end
    it "should change the language to es" do
      expect(User[2].language).to eq('es')
    end
  end


  context "when changing own name as analyst" do
    before(:context) do
      login_analyst
      User[2].update(:name=>'foo')
      put "/user/edit/name", :pk=>2, :value=>'bar'

    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
    it "should change the name to bar" do
      expect(User[2].name).to eq('bar')
    end
  end

  context "when changing other language as analyst" do
    before(:context) do
      login_analyst
      User[3].update(:language => 'en')
      put "/user/edit/language", :pk=>3, :value=>'es'

    end
    it "should response be not ok" do
      expect(last_response).to_not be_ok
    end
    it "should not change the language to es" do
      expect(User[3].language).to eq('en')
    end
  end


  context "when changing own password as analyst" do
    before(:context) do
      login_analyst
      post '/user/2/change_password', :password=>'dos2', :repeat_password=>'dos2'
    end
    it "should response be redirect" do
      expect(last_response).to be_redirect
    end
    it "should password be changed" do
      expect( User[:login=>'analyst'].correct_password?('dos2')).to be true
    end
    after(:context) do
      User[2].change_password("analyst")
    end


  end
  context "when changing another password as analyst" do
    before(:context) do
      login_analyst
      post '/user/3/change_password', :password=>'dos3', :repeat_password=>'dos3'
    end
    it "should response be not_ok" do
      expect(last_response).to_not be_ok
    end
    it "should password be changed" do
      expect( User[3].correct_password?('dos3')).to be false
    end

  end


end