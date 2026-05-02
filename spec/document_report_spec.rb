require 'spec_helper'

describe DocumentReport do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
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
      report_type:'duplicate',
      commentary:'Same document'
    )

    expect(report.status).to eq 'pending'
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
end
