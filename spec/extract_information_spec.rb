require 'rspec'
require_relative 'spec_helper'


describe 'Buhos extraction of data' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_test_sqlite
  end

  it 'should present a correct form'


  after(:all) do
    close_sqlite
  end

end