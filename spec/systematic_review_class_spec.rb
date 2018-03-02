require_relative 'spec_helper'


describe 'SystematicReview class' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
  end

  it "should be created by a form" do
    post '/login' , :user=>'admin', :password=>'admin'
    post '/review/update', :review_id=>'', :name=>'Test Review', :group_id=>1, :sr_administrator=>1
    rs_dataset=SystematicReview.where(:name=>'Test Review')
    expect(rs_dataset.count).to eq(1)
    rs=rs_dataset.first
    expect(rs[:name]).to eq("Test Review")
    expect(rs[:group_id]).to eq(1)
    expect(rs[:stage]).to eq('search')

  end


  after(:all) do
    close_sqlite
  end

end