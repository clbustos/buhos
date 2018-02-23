require 'rspec'
require_relative 'spec_helper'
require 'sinatra'



describe 'Buhos administration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_test_sqlite

  end


  it "shouldn't be accesible for analyst user" do
    post '/login' , :user=>'analyst', :password=>'analyst'
    not_permitted '/group/new'
    not_permitted '/role/new'
    not_permitted '/admin/users/'
    not_permitted '/user/new'
  end

  it "should be accesible for admin user" do
    post '/login' , :user=>'admin', :password=>'admin'
    permitted '/group/new'
    permitted '/admin/users/'

    permitted_redirect '/role/new'
    permitted_redirect '/user/new'
  end


  after(:all) do
    close_sqlite
  end

end