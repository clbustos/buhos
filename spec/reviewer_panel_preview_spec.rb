require 'spec_helper'

describe 'Reviewer panel previews' do
  include RSpecMixin

  before(:all) do
    configure_empty_database
    sr_for_report
    %w[screening_title_abstract screening_references review_full_text extract_information].each do |stage|
      AllocationCd.insert(systematic_review_id: 1, canonical_document_id: 1, user_id: 2, stage: stage)
    end
    login_admin
  end

  %w[screening_title_abstract screening_references review_full_text extract_information].each do |stage|
    it "opens a read-only #{stage} panel for the selected reviewer" do
      get "/review/1/#{stage}/preview/2"
      expect(last_response).to be_ok
      expect(last_response.body).to include('Panel preview for Analyst', 'inert')
      expect(last_response.body).to include(I18n.t(:Dashboard))
      dashboard=Nokogiri::HTML(last_response.body).at_css('.dashboard-user')
      expect(dashboard.css('.tab-pane.active').map {|pane| pane['id']}).to eq(["sr-1-#{SystematicReview[1].stage}"])
      expect(last_response.body).not_to include('.tab-pane { display: block; }')
      %w[search screening_title_abstract screening_references review_full_text extract_information report].each do |dashboard_stage|
        expect(last_response.body).to include("id='sr-1-#{dashboard_stage}'")
      end
      assigned_count=stage=='screening_references' ? 0 : 1
      expect(last_response.body).to include(I18n.t('user_dashboard.check_n_assigned_canonical_documents', count: assigned_count))
      expect(last_response.body).to include(I18n.t('user_dashboard.count_canonical_document_pending_information')) if stage=='extract_information'
      expect(last_response.body).to include('Title 1') unless stage=='screening_references'
      expect(last_response.headers['Content-Security-Policy']).to eq('sandbox allow-same-origin')
      get "/review/1/#{stage}"
      expect(last_response).to be_ok
      expect(last_response.body).not_to include('Title 1')
    end

    it "links to the #{stage} preview from administration in a new window" do
      get "/review/1/administration/#{stage}"
      expect(last_response).to be_ok
      expect(last_response.body).to include("/review/1/#{stage}/preview/2", "target='_blank'")
    end
  end

  it 'rejects a reviewer outside the review group' do
    get '/review/1/screening_title_abstract/preview/99999'
    expect(last_response.status).to eq(404)
  end

  it 'does not allow analysts to access previews' do
    login_analyst
    get '/review/1/screening_title_abstract/preview/1'
    expect(last_response.status).to eq(403)
    login_admin
  end
end
