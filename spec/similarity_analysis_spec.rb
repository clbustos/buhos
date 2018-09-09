require 'spec_helper'

describe 'Similarity Analysis ' do

  def pre_context
    create_sr
    @sr1=SystematicReview[1]
    @sr1.stage='report'
    CanonicalDocument.insert(:id=>1, :title=>"Title 1", :year=>0, :author=>'author_1', :doi=>nil, :abstract=>"aa aa aa aa")
    CanonicalDocument.insert(:id=>2, :title=>"Title 2", :year=>2000, :pmid=>1, :doi=>1234, :abstract=>"aa aa aa bb")
    CanonicalDocument.insert(:id=>3, :title=>"Title 3", :year=>0, :journal=>"J1", :doi=>nil, :abstract=>"aa aa cc bb")
    CanonicalDocument.insert(:id=>4, :title=>"Title 4", :year=>0, :journal=>"J2", :doi=>nil, :abstract=>nil)

    create_search
    Search[1].update(valid:true)
    create_record(n:4, search_id:[1,1,1,1], cd_id:[1,2,3,4])

  end

  def after_context
    $db[:records_searches].delete
    $db[:searches].delete
    $db[:records].delete
    $db[:resolutions].delete
    $db[:canonical_documents].delete
    $db[:systematic_reviews].delete
  end


  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    login_admin
    pre_context
  end

  after(:all) do
    after_context
  end

  context "when analyze similarity from a document with abstract" do
    let(:sasr) {Buhos::SimilarAnalysisSr.similar_to_cd_in_sr(cd:CanonicalDocument[1], sr:SystematicReview[1])}
    it "should be an array" do
      expect(sasr).to be_a(Array)
    end
    it "should only show similarity for id 2 and 3" do
      expect(sasr.find {|v| v[:id]==2}).to be_truthy
      expect(sasr.find {|v| v[:id]==3}).to be_truthy
      expect(sasr.find {|v| v[:id]==1}).to be_falsey
      expect(sasr.find {|v| v[:id]==4}).to be_falsey
    end
    it "should similarity for id:2 will be higher that for id:3" do
      expect(sasr.find {|v| v[:id]==2}[:similarity]).to be > sasr.find {|v| v[:id]==3}[:similarity]
    end
  end


  context "when analyze similarity from a document without abstract" do
    let(:sasr) {Buhos::SimilarAnalysisSr.similar_to_cd_in_sr(cd:CanonicalDocument[4], sr:SystematicReview[1])}
    it "should be nil" do
      expect(sasr).to be_nil
    end
  end



end