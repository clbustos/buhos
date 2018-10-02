require 'spec_helper'

describe 'QualityCriteriaProcessor:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr(n:1)
    #login_admin
  end

  after do
    $db[:sr_quality_criteria].delete
    $db[:cd_quality_criteria].delete
    $db[:quality_criteria].delete
  end
  def sr
    SystematicReview[1]
  end

  # .add_criterion

  context '.add_criterion_to_rs is called on a new quality criterion to a systematic review' do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}

    it "should create a successul Result" do
      QualityCriterion.get_criterion('criterion_1')
        res=Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      expect(res).to be_a(Result)
      expect(res.success?).to be true
    end

    it "should add a new sr_quality_criteria object" do

      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)

      sr_query=SrQualityCriterion.where(systematic_review_id:1, scale_id:scale[:id], quality_criterion_id:qc[:id])
      expect(sr_query.count).to eq(1)
      expect(sr_query.first[:order]).to eq(1)
    end
  end

  context '.add_criterion_to_rs is called on a already assigned quality criterion' do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}
    it "should create a Result with an error" do

      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      res=Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      expect(res).to be_a(Result)
      expect(res.success?).to be_falsey
    end
    it "should not add a new sr_quality_criteria object" do
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      expect(SrQualityCriterion.where(systematic_review_id:1, scale_id:scale[:id], quality_criterion_id:qc[:id]).count).to eq(1)
    end
  end

  context ".change_criterion_name is called on a text not used previously" do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}

    before do
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
    end
    it "should create a successful Result" do
      res=Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterio_2')
      expect(res).to be_a(Result)
      expect(res.success?).to be true
    end

    it "should rename the previous criterion text" do
      qc_id=qc[:id]
      Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterio_2')
      expect(QualityCriterion[id:qc_id].text).to eq('criterio_2')
    end
  end


  context ".change_criterion_name is called with already created cd_quality_criteria" do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}

    before do
      CanonicalDocument.insert(:id=>1, :title=>"Title 1", :year=>0)
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
      CdQualityCriterion.insert(systematic_review_id:1, canonical_document_id:1, quality_criterion_id:qc[:id], user_id:1, scale_id:scale[:id], value:1 )
    end

    it "should create a not successful Result" do
      res=Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterio_2')
      #$log.info(res)
      expect(res).to be_a(Result)
      expect(res.success?).to be false
    end

    it "should not rename the previous text" do
      expect(SrQualityCriterion[systematic_review_id:1, quality_criterion_id:qc[:id]]).to be_truthy
    end
    after do
      $db[:cd_quality_criteria].delete
      $db[:canonical_documents].delete
    end
  end


  context ".change_criterion_name is called on a criterion that already exists, but not in systematic review" do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}

    before do
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
    end

    it "should create a successful Result" do
      QualityCriterion.get_criterion('criterion_2')
      res=Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterion_2')
      expect(res).to be_a(Result)
      expect(res.success?).to be true
    end

    it "should rename the previous criterion text" do
      qc_new=QualityCriterion.get_criterion('criterion_2')
      Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterion_2')
      expect(SrQualityCriterion[systematic_review_id:1, quality_criterion_id:qc_new[:id]]).to be_truthy
    end
    it "should have the same scale and order" do
      old_info=SrQualityCriterion[systematic_review_id:1, quality_criterion_id:qc[:id]]
      order=old_info[:order]
      scale_id=old_info[:scale_id]
      qc_new=QualityCriterion.get_criterion('criterion_2')
      Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterion_2')
      new_sr_qc=SrQualityCriterion[systematic_review_id:1, quality_criterion_id:qc_new[:id]]
      expect(new_sr_qc[:order]).to    eq(order)
      expect(new_sr_qc[:scale_id]).to eq(scale_id)
    end
  end


  context ".change_criterion_name is called with the same name" do
    let(:qc) {QualityCriterion.get_criterion('criterion_1')}
    let(:scale) {Scale[1]}

    before do
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc,scale)
    end

    it "should create a erroneus Result" do
      res=Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterion_1')

      expect(res).to be_a(Result)
      expect(res.success?).to be false
    end

    it "should not create another sr_quality_criterion" do
      Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc,'criterion_1')
      expect(SrQualityCriterion.count).to eq(1)

    end
  end

  context ".change_criterion_name is called on a criterion that already exists on the systematic review" do
    let(:qc1) {QualityCriterion.get_criterion('criterion_1')}
    let(:qc2) {QualityCriterion.get_criterion('criterion_2')}
    let(:scale) {Scale[1]}

    before do
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc1,scale)
      Buhos::QualityCriteriaProcessor.add_criterion_to_rs(sr,qc2,scale)
    end

    it "should create a erroneus Result" do
      res=Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc2,'criterion_1')
      expect(res).to be_a(Result)

      expect(res.success?).to be false
    end

    it "should not create another sr_quality_criterion" do
      Buhos::QualityCriteriaProcessor.change_criterion_name(sr,qc2,'criterion_1')
      expect(SrQualityCriterion.count).to eq(2)

    end
  end




end