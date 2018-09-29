require 'spec_helper'

describe 'Quality criteria assessment' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr(n:1)


    login_admin
  end

  before do
    qc=QualityCriterion.get_criterion('criterion_1')
    Buhos::QualityCriteriaProcessor.add_criterion_to_rs(SystematicReview[id:1],qc,Scale[1])
  end

  after do
    $db[:sr_quality_criteria].delete
    $db[:cd_quality_criteria].delete
    $db[:quality_criteria].delete
  end
  def sr
    SystematicReview[1]
  end

  let(:qc) { QualityCriterion.get_criterion('criterion_1')}
  # .add_criterion

  context "when /review/:rs_id/quality_assesment_criteria is accessed" do
    before do
      get '/review/1/quality_assesment_criteria'
    end
    it "should be ok" do
      expect(last_response).to be_ok
    end
    it "should include criterion_1" do
      expect(last_response.body).to include('criterion_1')
    end
  end

  context "when /review/:rs_id/new_quality_criterion is used to create a new quality_criteria" do
    before(:context) do
      post '/review/1/new_quality_criterion', text:'criterion_2', scale_id:1
    end
    it "should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should include criterion_1 and 2" do
      get '/review/1/quality_assesment_criteria'
      expect(last_response.body).to include('criterion_1')
      expect(last_response.body).to include('criterion_2')
    end
  end


  context "when /review/:sr_id/edit_quality_criterion/:attr is used to modify attributes" do
    it "should change scale" do
      put "/review/1/edit_quality_criterion/scale_id", pk:qc[:id], value:2
      expect(SrQualityCriterion[quality_criterion_id:qc[:id] , systematic_review_id:1].scale_id).to eq(2)
    end

    it "should change text" do
      put "/review/1/edit_quality_criterion/text", pk:qc[:id], value:'criterion_2'
      expect(SrQualityCriterion[quality_criterion_id:qc[:id] , systematic_review_id:1].quality_criterion_id).to eq(QualityCriterion.get_criterion('criterion_2').id)
    end

  end

  context "when /review/:rs_id/new_quality_criterion is used to create a new quality_criteria" do
    before(:context) do
      post '/review/1/new_quality_criterion', text:'criterion_2', scale_id:1
    end
    it "should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should include criterion_1 and 2" do
      get '/review/1/quality_assesment_criteria'
      expect(last_response.body).to include('criterion_1')
      expect(last_response.body).to include('criterion_2')
    end
  end


  context "when /review/:sr_id/quality_criterion/:qc_id/delete is used to delete assignation to quality_criteria" do
    before do

      post "/review/1/quality_criterion/#{qc[:id]}/delete"
    end
    it "should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should not be any SrQualityCriterion" do
      expect(SrQualityCriterion.count).to eq(0)
    end
  end



end