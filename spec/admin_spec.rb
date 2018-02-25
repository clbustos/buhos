require_relative 'spec_helper'
require 'sinatra'



describe 'Buhos administration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_test_sqlite

  end


  context "when analyst try to access admin pages" do
    let(:login) {post '/login' , :user=>'analyst', :password=>'analyst'}

    it{login;expect('/admin/groups').to be_prohibited}
    it{login;expect('/group/new').to be_prohibited}
    it{login;expect('/role/new').to be_prohibited}
    it{login;expect('/admin/users').to be_prohibited}
    it{login;expect('/user/new').to be_prohibited}
  end

  context "when admin try to access admin pages" do
    let(:login) {post '/login' , :user=>'admin', :password=>'admin'}
    it  {expect('/admin/groups').to be_accesible_for_admin}
    it  {expect('/admin/roles').to be_accesible_for_admin}
    it {expect('/group/new').to be_accesible_for_admin}
    it {expect('/admin/users').to be_accesible_for_admin}
    it {expect('/user/new').to be_accesible_for_admin}

    it {login;permitted_redirect '/role/new'}
  end


  after(:all) do
    close_sqlite
  end

end