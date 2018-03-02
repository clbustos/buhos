require 'spec_helper'

describe 'Scopus_Abstract' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  before(:each) do
    login_admin
  end

  context ".get method" do
    it "should return with eid" do
      expect(Scopus_Abstract.get('eid', '2-s2.0-84893079388')).to be_truthy
    end
    it "should return with doi" do
      expect(Scopus_Abstract.get('doi', '10.1016/j.bjps.2013.09.004')[:id]).to eq('2-s2.0-84893079388')
    end
    it "should raise Buhos::NoScopusMethodError is id type is unknown" do
      expect {Scopus_Abstract.get('notype',10)}.to raise_exception(Buhos::NoScopusMethodError)
    end
  end
  context '.obtener_abstract_cd method' do
    it 'should return a Result object with error if abstract is not available' do
      result=Scopus_Abstract.obtener_abstract_cd(20)
      expect(result.success?).to be false
    end
  end
end