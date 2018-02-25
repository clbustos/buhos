require 'spec_helper'

describe 'Tags' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  before(:each) do
    post '/login' , :user=>'admin', :password=>'admin'
  end
  context 'when create a new tag class with a form' do

    let(:create_class_tag) {post '/tags/classes/new', {revision_id:1, etapa:nil, tipo:'documento',nombre:"New tag class"}}

    it {create_class_tag; expect(last_response).to be_redirect}
    it "is inserted on database" do expect(T_Clase.where(:nombre=>'New tag class').count).to eq(1) end
  end



end