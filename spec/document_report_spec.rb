require 'spec_helper'

describe DocumentReport do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    create_stage_dataset
    login_admin
  end

  before do
    DocumentReport.dataset.delete
  end

  it 'creates a pending report for a canonical document' do
    report=DocumentReport.create(
      systematic_review_id:1,
      canonical_document_id:1,
      user_id:1,
      report_type:DocumentReport::MISSING_FILE,
      commentary:'Missing file'
    )

    expect(report.status).to eq 'pending'
    expect(report.report_type).to eq 'missing_file'
    expect(report.user).to eq User[1]
    expect(report.systematic_review).to eq SystematicReview[1]
    expect(report.canonical_document).to eq CanonicalDocument[1]
  end

  it 'validates report type and status' do
    report=DocumentReport.new(
      systematic_review_id:1,
      canonical_document_id:1,
      user_id:1,
      report_type:'invalid_type',
      status:'invalid_status'
    )

    expect(report).not_to be_valid
    expect(report.errors.on(:report_type)).not_to be_nil
    expect(report.errors.on(:status)).not_to be_nil
  end

  it 'does not allow duplicated report types from the same user for the same document and review' do
    DocumentReport.create(
      systematic_review_id:1,
      canonical_document_id:1,
      user_id:1,
      report_type:'ocr_error'
    )

    duplicated=DocumentReport.new(
      systematic_review_id:1,
      canonical_document_id:1,
      user_id:1,
      report_type:'ocr_error'
    )

    expect(duplicated).not_to be_valid
    expect(duplicated.errors.on([:systematic_review_id, :canonical_document_id, :user_id, :report_type])).not_to be_nil
  end

  it 'sets resolved_at when the report is resolved' do
    report=DocumentReport.create(
      systematic_review_id:1,
      canonical_document_id:1,
      user_id:1,
      report_type:'wrong_metadata'
    )

    expect(report.resolved_at).to be_nil

    report.update(status:'resolved')

    expect(report.resolved_at).not_to be_nil
  end

  it 'updates multiple report types from x-editable' do
    put '/review/1/document_report/cd/1/user/1/report_types',
        value:['duplicate', 'ocr_error']

    expect(last_response).to be_ok
    expect(DocumentReport.where(systematic_review_id:1, canonical_document_id:1, user_id:1).map(:report_type).sort).
      to eq ['duplicate', 'ocr_error']

    put '/review/1/document_report/cd/1/user/1/report_types',
        value:['wrong_metadata']

    expect(last_response).to be_ok
    expect(DocumentReport.where(systematic_review_id:1, canonical_document_id:1, user_id:1).map(:report_type)).
      to eq ['wrong_metadata']

    put '/review/1/document_report/cd/1/user/1/report_types',
        value:''

    expect(last_response).to be_ok
    expect(DocumentReport.where(systematic_review_id:1, canonical_document_id:1, user_id:1).count).
      to eq 0
  end

  it 'shows the report button as inactive or active on screening pages' do
    get '/review/1/screening_title_abstract'

    expect(last_response).to be_ok
    expect(last_response.body).to include('document-report-1-1-1')
    expect(last_response.body).to include('document-report-editable btn btn-sm btn-default')
    expect(last_response.body).to include('document-report-count badge hidden')

    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'ocr_error')

    get '/review/1/screening_title_abstract'

    expect(last_response).to be_ok
    expect(last_response.body).to include('document-report-editable btn btn-sm btn-warning')
    expect(last_response.body).to include('data-value=\'duplicate,ocr_error\'')
    expect(last_response.body).to include('document-report-count badge')
    expect(last_response.body).to include('>2</span>')
  end

  it 'lets a review administrator report a search result and reject it administratively' do
    get '/review/1/canonical_documents', query:'Pager document 1'
    expect(last_response).to be_ok
    expect(last_response.body).not_to include('document-report-1-1-1')
    expect(last_response.body).to include('action_report', 'report_type')
    expect(last_response.body).not_to include('report_stage')
    expect(last_response.body).to include("type='button'")
    expect(last_response.body).to include('favorite-cd-1-user-1')

    post '/review/1/document_reports/batch', canonical_document:{'1'=>'1'},
         report_type:'spam'
    expect(last_response).to be_redirect

    get '/review/1/administration_document_reports'
    expect(last_response).to be_ok
    expect(last_response.body).to include('reported-document-1', 'Spam / Irrelevant Content')
    expect(last_response.body).to include('/resolution/review/1/canonical_document/1/stage/screening_title_abstract/resolution')

    post '/resolution/review/1/canonical_document/1/stage/screening_title_abstract/resolution',
         resolution:'no', user_id:1
    expect(last_response).to be_ok
    expect(Resolution.where(systematic_review_id:1, canonical_document_id:1,
                            stage:'screening_title_abstract').first.resolution).to eq('no')
  end

  it 'allows administrators without analysis permission to report' do
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_analyze').and_return(false)
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(true)
    put '/review/1/document_report/cd/1/user/1/report_types', value:['duplicate']
    expect(last_response).to be_ok
  end

  it 'reports only checked documents without duplicates and shows them across resolution stages' do
    2.times do
      post '/review/1/document_reports/batch', canonical_document:{'1'=>'1', '2'=>'1'},
           report_type:'duplicate'
      expect(last_response).to be_redirect
    end
    expect(DocumentReport.order(:canonical_document_id).map(:canonical_document_id)).to eq([1,2])

    get '/review/1/administration_document_reports', stage:'screening_title_abstract'
    expect(last_response.body).to include('reported-document-1', 'reported-document-2')
    get '/review/1/administration_document_reports', stage:'review_full_text'
    expect(last_response.body).to include('reported-document-1', 'reported-document-2')

    post '/review/1/document_reports/batch', canonical_document:{'1'=>'1'},
         report_type:'duplicate'
    expect(last_response).to be_redirect
    expect(DocumentReport.where(canonical_document_id:1).count).to eq(1)
  end

  it 'rejects empty selections and invalid report types' do
    [
      {report_type:'spam'},
      {canonical_document:{'1'=>'1'}, report_type:'invalid'}
    ].each do |data|
      post '/review/1/document_reports/batch', data
      expect(last_response.status).to eq(400)
    end
    expect(DocumentReport.count).to eq(0)
  end

  it 'rejects the entire selection if a document is outside the review' do
    post '/review/1/document_reports/batch', canonical_document:{'1'=>'1', '999'=>'1'},
         report_type:'spam'
    expect(last_response.status).to eq(403)
    expect(DocumentReport.count).to eq(0)
  end

  it 'requires review administration permission for batch reporting' do
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    post '/review/1/document_reports/batch', canonical_document:{'1'=>'1'},
         report_type:'spam'
    expect(last_response.status).to eq(403)
    expect(DocumentReport.count).to eq(0)
  end

  it 'rejects reports submitted in another user name' do
    put '/review/1/document_report/cd/1/user/2/report_types', value:['duplicate']
    expect(last_response.status).to eq(403)
    expect(DocumentReport.count).to eq(0)
  end

  it 'rejects reports for documents outside the review' do
    CanonicalDocument.insert(id:99, title:'Unrelated document', year:2020)
    put '/review/1/document_report/cd/99/user/1/report_types', value:['duplicate']
    expect(last_response.status).to eq(403)
    expect(DocumentReport.count).to eq(0)
  end

  it 'shows reports from all users of this review only' do
    SystematicReview.insert(id:2, name:'Another review', group_id:1, sr_administrator:1,
                            date_creation:Date.today, year_start:0, year_end:0) unless SystematicReview[2]
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:2, user_id:2, report_type:'ocr_error')
    DocumentReport.create(systematic_review_id:2, canonical_document_id:3, user_id:1, report_type:'spam')
    get '/review/1/administration_document_reports', stage:'review_full_text'
    expect(last_response).to be_ok
    expect(last_response.body).to include('reported-document-1', 'reported-document-2')
    expect(last_response.body).not_to include('reported-document-3')
    expect(last_response.body).to include('/stage/review_full_text/resolution')
  end

  it 'shows administrative reports without editing controls to read-only administrators' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin_view').and_return(true)
    get '/review/1/administration_document_reports'
    expect(last_response).to be_ok
    expect(last_response.body).to include('reported-document-1')
    expect(last_response.body).not_to include('dc_resolution')

    post '/resolution/review/1/canonical_document/1/stage/screening_title_abstract/resolution',
         resolution:'no', user_id:1
    expect(last_response.status).to eq(403)
  end

  it 'denies access to administrative reports without administrative permissions' do
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin_view').and_return(false)
    get '/review/1/administration_document_reports'
    expect(last_response.status).to eq(403)
  end
end
