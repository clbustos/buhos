require 'spec_helper'

describe 'Roles resources:' do


  shared_examples "authorized page" do |parameter|
    let(:route) { parameter }
    it "should be accessible for admin" do
      login_admin

      get route
      expect(last_response).to be_ok
    end
    it "should not be accessible for analyst" do
      login_analyst
      get route
      expect(last_response).to_not be_ok
    end

  end

  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite

  end
  routes=["/admin/roles","/role/new", "/role/analyst", "/role/guest/edit"]
  routes.each do |route|
    describe route do
      it_behaves_like "authorized page" do
        let(:route) {route}
      end
    end
  end
#  include_examples "authorizations", "/role/new"
#  include_examples "authorizations", "/role/id"
#  include_examples "authorizations", "/role/1/edit"

  context 'when /admin/roles is retrieved as admin' do
    before(:context) do
      login_admin
      get '/admin/roles'
    end
    it "should have button for new role" do
      expect(last_response.body).to include(I18n::t(:Role_new))
    end
  end

  context "when /role/X/delete is used" do
    it "should delete user if admin" do
      login_admin
      Role.insert(id:"new_role", description:"Boring role")
      expect(Role['new_role']).to be_truthy
      post '/role/new_role/delete'
      expect(Role['new_role']).to be_falsey
    end
    it "should not delete user if admin" do
      login_analyst
      Role.insert(id:"new_role", description:"Boring role")
      expect(Role['new_role']).to be_truthy
      post '/role/new_role/delete'
      expect(Role['new_role']).to be_truthy
    end

    after do
      Role.where(:id=>'new_role').delete
    end
  end

  context "when /role/update is used" do
    it "should edit a role by admin" do
      login_admin
      Role.insert(id:"new_role", description:"Boring role")
      post '/role/update', role_id_old: 'new_role', role_id_new:'new_role_2', description:"Dups", authorizations:['role_view']

      expect(last_response).to be_redirect
      expect(Role['new_role']).to be_falsey
      expect(Role['new_role_2']).to be_truthy
      expect(Role['new_role_2'].description).to eq("Dups")
      expect(AuthorizationsRole.where(:role_id=>'new_role_2').count).to eq(1)
    end
    it "should not edit a role by admin" do
      login_analyst
      Role.insert(id:"new_role", description:"Boring role")
      post '/role/update', role_id_old: 'new_role', role_id_new:'new_role_2', description:"Dups", authorizations:['role_view']
      expect(last_response).to_not be_ok
    end
    after do
      Role.where(:id=>'new_role').delete
    end

  end

end