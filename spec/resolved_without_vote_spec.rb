require 'spec_helper'

describe 'Assignments without votes on resolved documents' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    sr_for_report
    CanonicalDocument.insert(id:2, title:'Unresolved document', year:2020)
    SystematicReview.insert(id:2, name:'Other review', group_id:1, sr_administrator:1,
                            date_creation:Date.today, year_start:0, year_end:0)
    login_admin
  end

  before do
    AllocationCd.dataset.delete
    Decision.dataset.delete
    Resolution.dataset.delete
  end

  def assign(cd_id, user_id, stage, review_id=1)
    AllocationCd.insert(systematic_review_id:review_id, canonical_document_id:cd_id, user_id:user_id, stage:stage)
  end

  %w[screening_title_abstract screening_references review_full_text].each do |stage|
    it "lists and removes only assignments without votes in #{stage}" do
      assign(1,1,stage)
      assign(1,2,stage)
      assign(2,1,stage)
      assign(1,1,'extract_information')
      assign(1,1,stage,2)
      Decision.insert(systematic_review_id:1, canonical_document_id:1, user_id:2, stage:stage, decision:'undecided')
      Resolution.set_for_document(systematic_review_id:1, canonical_document_id:1, stage:stage, resolution:'no', user_id:1)
      Resolution.set_for_document(systematic_review_id:2, canonical_document_id:1, stage:stage, resolution:'yes', user_id:1)

      get "/review/1/administration/#{stage}"
      expect(last_response).to be_ok
      expect(last_response.body).to include("/review/1/administration/#{stage}/resolved_without_vote")
      get "/review/1/administration/#{stage}/resolved_without_vote"
      expect(last_response).to be_ok
      row=Nokogiri::HTML(last_response.body).at_css('#resolved-without-vote-1')
      expect(row.text).to include(User[1].name)
      expect(row.text).not_to include(User[2].name)
      expect(last_response.body).not_to include('resolved-without-vote-2')
      decisions=Decision.all.map(&:values)
      resolutions=Resolution.all.map(&:values)

      post "/review/1/administration/#{stage}/resolved_without_vote/unassign"
      expect(last_response).to be_redirect
      expect(AllocationCd.where(systematic_review_id:1, canonical_document_id:1, stage:stage).select_map(:user_id)).to eq([2])
      expect(AllocationCd.count).to eq(4)
      expect(Decision.all.map(&:values)).to eq(decisions)
      expect(Resolution.all.map(&:values)).to eq(resolutions)
      post "/review/1/administration/#{stage}/resolved_without_vote/unassign"
      expect(AllocationCd.count).to eq(4)
    end
  end

  it 'rechecks votes at removal and handles empty decisions as no vote' do
    stage='screening_title_abstract'
    assign(1,1,stage)
    assign(1,2,stage)
    Decision.insert(systematic_review_id:1, canonical_document_id:1, user_id:1, stage:stage, decision:nil)
    Decision.insert(systematic_review_id:1, canonical_document_id:1, user_id:2, stage:stage, decision:Decision::NO_DECISION)
    Resolution.set_for_document(systematic_review_id:1, canonical_document_id:1, stage:stage, resolution:'yes', user_id:1)
    get "/review/1/administration/#{stage}/resolved_without_vote"
    expect(last_response.body).to include('resolved-without-vote-1')
    Decision.where(user_id:1).update(decision:'yes')
    post "/review/1/administration/#{stage}/resolved_without_vote/unassign"
    expect(AllocationCd.select_map(:user_id)).to eq([1])
  end

  it 'allows viewing but prevents removal with read-only administration permission' do
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin_view').and_return(true)
    get '/review/1/administration/review_full_text/resolved_without_vote'
    expect(last_response).to be_ok
    expect(last_response.body).not_to include('/resolved_without_vote/unassign')
    post '/review/1/administration/review_full_text/resolved_without_vote/unassign'
    expect(last_response.status).to eq(403)
  end

  it 'rejects unsupported stages' do
    get '/review/1/administration/invalid/resolved_without_vote'
    expect(last_response.status).to eq(400)
    post '/review/1/administration/invalid/resolved_without_vote/unassign'
    expect(last_response.status).to eq(400)
  end
end
