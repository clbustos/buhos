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
    cp.update_criteria({"new"=>""}   , {"new"=>""})
    expect(SrCriterion.where(systematic_review_id:1).empty?).to be_truthy
  end
  context "with some predefined criteria" do
    before do
      SrCriterion.sr_criterion_add(@sr, crit(1), 'inclusion')
      SrCriterion.sr_criterion_add(@sr, crit(2), 'exclusion')
      CdCriterion.insert(criterion_id:crit(1)[:id], canonical_document_id:1, user_id:1, systematic_review_id:1, selected:true)
    end

    it "should add a criterion" do
      cp.update_criteria({crit(1)[:id]=>"criterion_1",  'new'=>"criterion_3"}   , {crit(2)[:id]=>"criterion_2"})
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id],crit(3)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([crit(2)[:id]])
    end
    it "should not add a criterion if text is empty" do
      cp.update_criteria({crit(1)[:id]=>"criterion_1",  'new'=>""}   , {crit(2)[:id]=>"criterion_2"})
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([crit(2)[:id]])
    end

    it "should remove a criterion" do
      cp.update_criteria({crit(1)[:id]=>"criterion_1"}, {})
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([])
    end
    it "should change criterion name, if unused" do
      id_crit_2=crit(2)[:id]
      expect(Criterion.count).to eq(2)
      cp.update_criteria({crit(1)[:id]=>"criterion_1"}, {id_crit_2=>"criterion_2_new"})
      expect(Criterion.count).to eq(2)
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([id_crit_2])
      expect(Criterion[id_crit_2][:text]).to eq("criterion_2_new")
    end
    it "should not change criterion name, if used" do
      id_crit_1=crit(1)[:id]
      cp.update_criteria({id_crit_1=>"criterion_1_new"}, {crit(2)[:id]=>"criterion_2"})
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'inclusion').map(:criterion_id).sort).to eq([crit(1)[:id]])
      expect(SrCriterion.where(systematic_review_id:1, criteria_type:'exclusion').map(:criterion_id).sort).to eq([crit(2)[:id]])
      expect(Criterion[id_crit_1][:text]).to eq("criterion_1")
      expect(cp.error).to be_truthy
    end

    after do
      $db[:sr_criteria].delete
      $db[:cd_criteria].delete
      $db[:criteria].delete
    end
  end


end