require 'rspec'
require_relative 'spec_helper'


describe 'SystematicReview class' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_test_sqlite
  end

  it "should be created by a form" do
    post '/login' , :user=>'admin', :password=>'admin'

  end


  after(:all) do
    close_sqlite
  end

end