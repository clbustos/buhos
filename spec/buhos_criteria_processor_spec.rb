require 'spec_helper'

describe 'Buhos::CriteriaProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr(n:1)
    CanonicalDocument.insert(id:1, year:2000, title:"cd 1")
    @sr=SystematicReview[1]

  end
  def crit(i)
    Criterion.get_criterion("criterion_#{i}")
  end
  let(:cp) {Buhos::CriteriaProcessor.new(@sr)}
  it "should do nothing if empty" do
    cp.update_criteria([]   , [])
    expect(SrCriterion.where(systematic_review_id:1).empty?).to be_truthy
  end
  context "with some predefined criteria" do
    before do
      SrCriterion.sr_criterion_add(@sr, crit(1), 'inclusion')
      SrCriterion.sr_criterion_add(@sr, crit(2), 'exclusion')
      CdCriterion.insert(criterion_id:crit(1)[:id], canonical_document_id:1, user_id:1, systematic_review_id:1, presence:CdCriterion::PRESENT_YES)
    end

    it "should add a criterion" do
      cp.update_criteria(["criterion_1", "criterion_3"]   , ["criterion_2"])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id],crit(3)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([crit(2)[:id]])
    end
    it "should not add a criterion if text is empty" do
      cp.update_criteria(["criterion_1",  ""]   , ["criterion_2"])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([crit(2)[:id]])
    end

    it "should remove a criterion" do
      cp.update_criteria(["criterion_1"], [])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([])
    end

    after do
      $db[:sr_criteria].delete
      $db[:cd_criteria].delete
      $db[:criteria].delete
    end
  end


end