require 'spec_helper'

describe 'Criteria related models' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr(n:1)
    login_admin
  end
  after do
    $db[:sr_criteria].delete
    $db[:cd_criteria].delete
    $db[:canonical_documents].delete
    $db[:criteria].delete
  end
  let(:sr) {SystematicReview[1]}



  context "Criterion model" do

    it ".get_criteria should create a new criteria" do
      expect(Criterion.count).to eq(0)
      criterion_1=Criterion.get_criterion('test1')
      expect(criterion_1).to be_truthy
      expect(Criterion[:text=>'test1']).to be_truthy
    end
  end
  context "SrCriterion model" do
    it ".sr_criterion_add should add a new criteria to sr" do
      criterion_1=Criterion.get_criterion('test1')
      SrCriterion.sr_criterion_add(sr, criterion_1, 'inclusion')
      expect(SrCriterion.count).to eq(1)
    end
    it ".sr_criterion_add on an already added criterion do nothing" do
      criterion_1=Criterion.get_criterion('test1')
      SrCriterion.sr_criterion_add(sr, criterion_1, 'inclusion')
      criterion_1=Criterion.get_criterion('test1')
      SrCriterion.sr_criterion_add(sr, criterion_1, 'exclusion')
      expect(SrCriterion.count).to eq(1)
    end

    it ".sr_criterion_remove should remove a criterion on sr" do
      criterion_1=Criterion.get_criterion('test1')
      SrCriterion.sr_criterion_add(sr, criterion_1, 'inclusion')
      expect(SrCriterion.count).to eq(1)
      SrCriterion.sr_criterion_remove(sr, criterion_1)
      expect(SrCriterion.count).to eq(0)
    end
    it ".sr_criterion_remove should do nothing if remove a criterion doesn't associate to sr" do
      criterion_1=Criterion.get_criterion('test1')
      criterion_2=Criterion.get_criterion('test2')
      SrCriterion.sr_criterion_add(sr, criterion_1, 'inclusion')
      expect(SrCriterion.count).to eq(1)
      SrCriterion.sr_criterion_remove(sr, criterion_2)
      expect(SrCriterion.count).to eq(1)
    end
  end

  context "when /review/criteria/id is called" do
    before do
      CanonicalDocument.insert(id:1, title:"CD1", :year=>1)
      criterion_1=Criterion.get_criterion('test1')
      SrCriterion.sr_criterion_add(sr,criterion_1,'inclusion')
      post '/review/criteria/cd', cd_id:1,sr_id:1, user_id:1, criterion_id:criterion_1[:id], presence:CdCriterion::PRESENT_YES
    end
    it "shoud response be correct" do
      expect(last_response).to be_ok
    end
    it "should response include an id object" do

      expect(last_response.body).to include('criteria-user-1-1-1')
    end
    it "should add a CdCriterion object" do
      #p CdCriterion.all
      expect(CdCriterion[canonical_document_id:1, criterion_id: Criterion.get_criterion('test1')[:id], user_id:1, systematic_review_id:1][:presence]).to eq(CdCriterion::PRESENT_YES)
    end

  end



end