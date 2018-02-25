require_relative 'spec_helper'

describe 'Review with all stages completed' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }

    configure_complete_sqlite


  end


  it { expect("/").to be_accesible_for_admin}
  context "when review resources are accessed" do

    it { expect("/review/1").to be_accesible_for_admin}
    it { expect("/review/1/edit").to be_accesible_for_admin}
    it { expect("/review/1/canonical_documents").to be_accesible_for_admin}

    it { expect("/review/1/searchs").to be_accesible_for_admin}
    it { expect("/review/1/tags").to be_accesible_for_admin}
    it { expect("/review/1/messages").to be_accesible_for_admin}
    it { expect("/review/1/fields").to be_accesible_for_admin}
    it { expect("/review/1/administration_stages").to be_accesible_for_admin}

    it { expect("/review/1/administration/search").to be_accesible_for_admin}
    it { expect("/review/1/searchs/user/1").to be_accesible_for_admin}
    it { expect("/review/1/search/new").to be_accesible_for_admin}
    it { expect("/review/1/searchs/compare_records").to be_accesible_for_admin}
  end
  context "when search resources are accessed" do
    it { expect("/search/1").to be_accesible_for_admin}
    it { expect("/search/1/edit").to be_accesible_for_admin}
    it { expect("/search/1/records").to be_accesible_for_admin}
    it { expect("/search/1/references").to be_accesible_for_admin}
  end
end