require 'spec_helper'

describe 'Reviewer agreement' do
  include RSpecMixin

  before do
    configure_empty_database
    sr_for_report
    (2..5).each {|id| CanonicalDocument.insert(id:id, title:"Document #{id}", year:2020)}
    @review=SystematicReview[1]
    @stage='screening_title_abstract'
    Decision.where(systematic_review_id:1).delete
    Resolution.where(systematic_review_id:1).delete
    allow(@review).to receive(:cd_id_by_stage).and_return([1, 2, 3, 4, 5])
    {1=>%w[yes no undecided yes ND], 2=>%w[yes yes undecided no no]}.each do |user, decisions|
      decisions.each_with_index do |decision, index|
        Decision.insert(systematic_review_id:1, stage:@stage, user_id:user,
                        canonical_document_id:index+1, decision:decision)
      end
    end
    %w[yes no yes].each_with_index do |resolution, index|
      Resolution.insert(systematic_review_id:1, stage:@stage, user_id:1,
                        canonical_document_id:index+1, resolution:resolution)
    end
  end

  it 'compares explicit votes to binary resolutions and includes undecided as incorrect' do
    result=Analysis_SR_Stage.new(@review, @stage).reviewer_agreement
    expect(result[:accuracy][1]['yes']).to eq(matches:1, total:2, percentage:50.0)
    expect(result[:accuracy][1]['no']).to eq(matches:1, total:1, percentage:100.0)
    expect(result[:accuracy][1][:total][:percentage]).to be_within(0.001).of(200.0/3)
    expect(result[:accuracy][2][:total][:matches]).to eq(1)
  end

  it 'computes symmetric exact agreement on shared explicit votes, including unresolved documents' do
    result=Analysis_SR_Stage.new(@review, @stage).reviewer_agreement
    expect(result[:matrix][1][2]).to eq(matches:2, total:4, percentage:50.0)
    expect(result[:matrix][2][1]).to eq(result[:matrix][1][2])
    expect(result[:matrix][1][1][:percentage]).to eq(100.0)
  end

  it 'returns no percentage without comparable data' do
    Decision.where(systematic_review_id:1).delete
    result=Analysis_SR_Stage.new(@review, @stage).reviewer_agreement
    expect(result[:accuracy][1][:total]).to eq(matches:0, total:0, percentage:nil)
    expect(result[:matrix][1][2][:percentage]).to be_nil
  end

  it 'opens the panel for each supported stage and rejects unsupported stages' do
    login_admin
    %w[screening_title_abstract screening_references review_full_text].each do |stage|
      get "/review/1/administration/#{stage}/reviewer_agreement"
      expect(last_response).to be_ok
      expect(last_response.body).to include('Absolute agreement matrix', 'Analyst')
      get "/review/1/administration/#{stage}"
      expect(last_response.body).to include("/review/1/administration/#{stage}/reviewer_agreement")
    end
    get '/review/1/administration/extract_information/reviewer_agreement'
    expect(last_response.status).to eq(400)
    login_analyst
    get '/review/1/administration/screening_title_abstract/reviewer_agreement'
    expect(last_response.status).to eq(403)
  end
end
