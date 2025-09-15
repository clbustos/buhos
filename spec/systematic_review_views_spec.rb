require_relative 'spec_helper'


describe 'SystematicReviewViewsMixin' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    login_admin
  end
  let(:sr) {SystematicReview[1]}
  context "when a standard review is created and count_references_bw_canonical is called" do
    before(:context) do
      sr_for_report
      @sr=SystematicReview[1]
      CanonicalDocument.insert(:id=>2, :title=>"Title 2", :year=>0)

      create_record(:id=>[2],:cd_id=>[2], :search_id=>1 )

      @sr.count_references_bw_canonical
    end

    it "#cd_id_table is correct" do
      cd_ids=sr.cd_id_table.all
      expect(cd_ids.length).to eq(2)
    end
    it "#references_bw_canonical is correct" do
      cd_ids=sr.references_bw_canonical.all
      expect(cd_ids.length).to eq(0)
    end

    after(:context) do
      sr_for_report_down
    end
  end


  context "when a standard review is created and count_references_rtr is called" do
    before(:context) do
      sr_for_report
      CanonicalDocument.insert(:id=>2, :title=>"Title 2", :year=>0)
      create_record(:id=>[2], :cd_id=>[2], :search_id=>1 )

      @sr=SystematicReview[1]
      @sr.count_references_rtr
    end

    it "#cd_id_table is correct" do
      cd_ids=sr.cd_id_table.all
      expect(cd_ids.length).to eq(2)
    end
    it "#references_bw_canonical is correct" do
      rbc=sr.references_bw_canonical.all
      expect(rbc.length).to eq(0)
    end

    it "#resolutions_title_abstract is correct" do
      rta=sr.resolutions_title_abstract.all

      expect(rta.map {|v| v[:commentary]}).to eq(['STA1'])
    end

    after(:context) do
      sr_for_report_down
    end
  end

  after(:all) do
    close_sqlite
  end
end