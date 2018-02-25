require_relative 'spec_helper'


describe 'SystematicReview class' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
  end

  it "should be created by a form" do
    post '/login' , :user=>'admin', :password=>'admin'
    post '/review/update', :revision_id=>'', :nombre=>'Test Review', :grupo_id=>1, :administrador_revision=>1
    rs_dataset=Revision_Sistematica.where(:nombre=>'Test Review')
    expect(rs_dataset.count).to eq(1)
    rs=rs_dataset.first
    expect(rs[:nombre]).to eq("Test Review")
    expect(rs[:grupo_id]).to eq(1)
    expect(rs[:etapa]).to eq('search')

  end


  after(:all) do
    close_sqlite
  end

end