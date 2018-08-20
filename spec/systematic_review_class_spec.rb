require_relative 'spec_helper'


describe 'SystematicReview class' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    post '/login' , :user=>'admin', :password=>'admin'

  end
  let(:rs_dataset) {SystematicReview.where(:name=>'Test Review')}
  let(:rs) {SystematicReview.where(:name=>'Test Review').first}
  context "when created by a form" do
    before(:context) do
      post '/review/update', :review_id=>'', :name=>'Test Review',
           :group_id=>1,
           :sr_administrator=>1,
           :criteria=>{"inclusion"=>{"new"=>"inclusion_1"}, "exclusion"=>{"new"=>"exclusion_2"}}
    end
    it "generate a single object" do
    expect(rs_dataset.count).to eq(1)
    end
    it "should have correct name" do
    expect(rs[:name]).to eq("Test Review")
    end
    it "should have correct group" do
    expect(rs[:group_id]).to eq(1)
    end
    it "should have correct stage" do
    expect(rs[:stage]).to eq('search')
    end
    it "should be associated to correct criteria" do
      sr_cr=Criterion.join(:sr_criteria, criterion_id: :id).where(:systematic_review_id=>rs.id)
      expect(sr_cr.count).to eq(2)
      expect(sr_cr.map(:text).sort).to eq(['exclusion_2','inclusion_1'])
    end
    after(:context) do
      $db[:sr_criteria].delete
      $db[:criteria].delete
      $db[:systematic_reviews].delete
    end
  end
  context "when deleted by a form" do
    before do
      post '/review/update', :review_id=>'', :name=>'Test Review deleted',
           :group_id=>1,
           :sr_administrator=>1,
           :criteria=>{"inclusion"=>{"new"=>"inclusion_1"}, "exclusion"=>{"new"=>"exclusion_2"}}
    end
    def rs_deleted
      SystematicReview.where(:name=>'Test Review deleted').first
    end


    it "should be 1 systematic review before delete" do
      expect(rs_deleted).to be_truthy
    end
    it "should be 0 systematic review after delete" do
      post "/review/#{rs_deleted[:id]}/delete2", sr_id: rs_deleted[:id]
      expect(rs_deleted).to be_falsey
    end
    after() do
      $db[:sr_criteria].delete
      $db[:criteria].delete
      $db[:systematic_reviews].delete
    end

  end

  after(:all) do
    close_sqlite
  end

end