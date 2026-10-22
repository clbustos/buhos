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

  it 'omits resolved report indicators while retaining pending reasons in canonical lists' do
    report=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1,
                                 report_type:'duplicate', status:'resolved')
    get '/review/1/canonical_documents', query:'Pager document 1'
    html=Nokogiri::HTML(last_response.body)
    expect(html.at_css('#canonical-document-1 .canonical-document-reported')).to be_nil

    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2,
                          report_type:'does_not_meet_criteria')
    get '/review/1/canonical_documents', query:'Pager document 1'
    badge=Nokogiri::HTML(last_response.body).at_css('#canonical-document-1 .canonical-document-reported')
    expect(badge.text).to include('Does not meet criteria')
    expect(badge.text).not_to include('Duplicate Document')
    expect(report.refresh.status).to eq('resolved')
  end

  it 'shows every report author and current status at the end of the canonical detail for this review' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate', status:'resolved')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:'spam', status:'ignored')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:'does_not_meet_criteria')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:2, user_id:1, report_type:'ocr_error')
    SystematicReview.insert(id:2, name:'Other review', group_id:1, sr_administrator:1,
                            date_creation:Date.today, year_start:0, year_end:0) unless SystematicReview[2]
    DocumentReport.create(systematic_review_id:2, canonical_document_id:1, user_id:1, report_type:'missing_file')
    get '/review/1/canonical_document/1'
    expect(last_response).to be_ok
    section=Nokogiri::HTML(last_response.body).at_css('#canonical-document-reports')
    rows=section.css('tbody tr').map {|row| row.css('td').map {|cell| cell.text.strip}}
    expect(rows).to contain_exactly(
      ['Duplicate Document', User[1].name, 'Resolved'],
      ['Spam / Irrelevant Content', User[2].name, 'Ignored'],
      ['Does not meet criteria', User[2].name, 'Pending']
    )
  end

  it 'shows an empty report section when the canonical document has no reports' do
    get '/review/1/canonical_document/1'
    expect(last_response).to be_ok
    section=Nokogiri::HTML(last_response.body).at_css('#canonical-document-reports')
    expect(section.text).to include('This document has no reports in this review.')
  end

  it 'provides the same AJAX status control in canonical details and administration' do
    report=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:'duplicate')
    get '/review/1/canonical_document/1'
    expect(last_response).to be_ok
    button=Nokogiri::HTML(last_response.body).at_css('#canonical-document-reports .report-resolved-button')
    expect(button['disabled']).to be_nil
    expect(button['data-resolved']).to eq('false')
    endpoint=button['data-url']
    put endpoint, resolved:'true'
    expect(last_response).to be_ok
    expect(report.refresh.status).to eq('resolved')
    ['/review/1/canonical_document/1', '/review/1/administration_document_reports'].each do |path|
      get path
      button=Nokogiri::HTML(last_response.body).at_css("button[data-url='#{endpoint}']")
      expect(button['data-resolved']).to eq('true')
      expect(button['class']).to include('btn-success')
    end
    put endpoint, resolved:'false'
    expect(last_response).to be_ok
    expect(report.refresh.status).to eq('pending')
  end

  it 'disables report status editing in canonical details without administration permission' do
    report=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    get '/review/1/canonical_document/1'
    expect(last_response).to be_ok
    button=Nokogiri::HTML(last_response.body).at_css('#canonical-document-reports .report-resolved-button')
    expect(button['disabled']).not_to be_nil
    put button['data-url'], resolved:'true'
    expect(last_response.status).to eq(403)
    expect(report.refresh.status).to eq('pending')
  end

  it 'hides documents resolved only in the selected stage, independently of report status' do
    [1,2,3].each do |cd_id|
      DocumentReport.create(systematic_review_id:1, canonical_document_id:cd_id, user_id:1, report_type:'duplicate')
    end
    Resolution.where(systematic_review_id:1, canonical_document_id:[1,2,3]).delete
    Resolution.set_for_document(systematic_review_id:1, canonical_document_id:1, stage:'review_full_text', resolution:'yes', user_id:1)
    Resolution.set_for_document(systematic_review_id:1, canonical_document_id:2, stage:'review_full_text', resolution:'no', user_id:1)
    Resolution.set_for_document(systematic_review_id:1, canonical_document_id:3, stage:'screening_title_abstract', resolution:'no', user_id:1)
    DocumentReport.where(canonical_document_id:3).first.update(status:'resolved')

    get '/review/1/administration_document_reports', stage:'review_full_text', hide_resolved:'true'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    expect(html.css('tr[id^="reported-document-"]').map {|row| row['id']}).to eq(['reported-document-3'])
    expect(html.at_css('input[name="hide_resolved"]')['checked']).not_to be_nil
    expect(last_response.body).to include('hide_resolved=true')

    get '/review/1/administration_document_reports', stage:'review_full_text'
    expect(last_response.body).to include('reported-document-1', 'reported-document-2', 'reported-document-3')
  end

  it 'marks individual reports as resolved and reopens them without changing document resolutions' do
    report=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:'duplicate')
    other=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'spam')
    resolutions=Resolution.all.map(&:values)
    put "/review/1/document_report/#{report.id}/resolved", resolved:'true'
    expect(last_response).to be_ok
    expect(JSON.parse(last_response.body)['status']).to eq('resolved')
    expect(report.refresh.status).to eq('resolved')
    expect(report.resolved_at).not_to be_nil
    expect(other.refresh.status).to eq('pending')
    expect(Resolution.all.map(&:values)).to eq(resolutions)

    get '/review/1/administration_document_reports'
    html=Nokogiri::HTML(last_response.body)
    button=html.at_css("button[data-url='/review/1/document_report/#{report.id}/resolved']")
    expect(button['data-resolved']).to eq('true')
    expect(button['aria-pressed']).to eq('true')
    expect(button['class']).to include('btn-success')
    expect(button.text).to include('Resolved')
    expect(html.css('.document-report-entry input[type="checkbox"]')).to be_empty
    put "/review/1/document_report/#{report.id}/resolved", resolved:'false'
    expect(last_response).to be_ok
    expect(report.refresh.status).to eq('pending')
    expect(report.resolved_at).to be_nil
    get '/review/1/administration_document_reports'
    button=Nokogiri::HTML(last_response.body).at_css("button[data-url='/review/1/document_report/#{report.id}/resolved']")
    expect(button['data-resolved']).to eq('false')
    expect(button['class']).to include('btn-default')
    expect(button.text).to include('Pending')
  end

  it 'requires administration permission and the correct review to resolve a report' do
    report=DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    put "/review/999/document_report/#{report.id}/resolved", resolved:'true'
    expect(last_response.status).to eq(404)
    put "/review/1/document_report/#{report.id}/resolved", resolved:'invalid'
    expect(last_response.status).to eq(400)
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).and_call_original
    allow_any_instance_of(Sinatra::Application).to receive(:auth_to).with('review_admin').and_return(false)
    put "/review/1/document_report/#{report.id}/resolved", resolved:'true'
    expect(last_response.status).to eq(403)
    expect(report.refresh.status).to eq('pending')
  end

  it 'filters canonical documents by any report or a specific reason only when enabled' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2, report_type:'duplicate')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:2, user_id:2, report_type:'does_not_meet_criteria')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:3, user_id:1, report_type:'duplicate', status:'ignored')

    get '/review/1/canonical_documents', only_reported:'true', report_filter:'any'
    expect(last_response).to be_ok
    rows=Nokogiri::HTML(last_response.body).css('tr[id^="canonical-document-"]').map {|row| row['id']}
    expect(rows.sort).to eq(%w[canonical-document-1 canonical-document-2])

    get '/review/1/canonical_documents', only_reported:'true', report_filter:'does_not_meet_criteria'
    expect(last_response).to be_ok
    rows=Nokogiri::HTML(last_response.body).css('tr[id^="canonical-document-"]').map {|row| row['id']}
    expect(rows).to eq(['canonical-document-2'])
    expect(Nokogiri::HTML(last_response.body).at_css('select[name="report_filter"] option[selected]')['value']).to eq('does_not_meet_criteria')

    get '/review/1/canonical_documents', report_filter:'does_not_meet_criteria'
    expect(last_response.body).to include('canonical-document-1', 'canonical-document-2', 'canonical-document-3')

    get '/review/1/canonical_documents', only_reported:'true', report_filter:'spam'
    expect(last_response).to be_ok
    expect(Nokogiri::HTML(last_response.body).css('tr[id^="canonical-document-"]')).to be_empty
  end

  it 'preserves report filters in pagination, sorting and the return URL while combining search filters' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1, report_type:'duplicate')
    get '/review/1/canonical_documents', only_reported:'true', report_filter:'duplicate',
        query:'Pager document 1', only_records:'true', wo_abstract:'true', order:'title__asc'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    expect(html.at_css('#canonical-document-1')).not_to be_nil
    links=html.css('.pagination a, .btn-group a').select {|link| link['href'].include?('order=')}
    expect(links).not_to be_empty
    links.each do |link|
      values=URI.decode_www_form(URI(link['href']).query).to_h
      expect(values).to include('only_reported'=>'true', 'report_filter'=>'duplicate',
                               'query'=>'Pager document 1', 'only_records'=>'true', 'wo_abstract'=>'true')
    end
    return_to=html.at_css('input[name="report_return_to"]')['value']
    expect(URI.decode_www_form(URI(return_to).query).to_h).to include('only_reported'=>'true', 'report_filter'=>'duplicate')
  end

  it 'returns to the exact canonical search URL after reporting' do
    search_url='/review/1/canonical_documents?query=Pager+document&page=2&order=title__asc&only_records=true&wo_abstract=true'
    get search_url
    expect(last_response).to be_ok
    return_to=Nokogiri::HTML(last_response.body).at_css('input[name="report_return_to"]')['value']
    expect(return_to).to eq(search_url)

    post '/review/1/document_reports/batch', canonical_document:{'1'=>'1'},
         report_type:'does_not_meet_criteria', report_return_to:return_to
    expect(last_response).to be_redirect
    expect(URI(last_response.location).request_uri).to eq(search_url)
    expect(DocumentReport.where(canonical_document_id:1, report_type:'does_not_meet_criteria').count).to eq(1)
  end

  it 'falls back to the same review canonical list for missing or unrelated return URLs' do
    [nil, 'https://example.com', '//example.com', '/review/2/canonical_documents',
     '/review/1/administration_document_reports'].each do |return_to|
      post '/review/1/document_reports/batch', canonical_document:{'1'=>'1'},
           report_type:'spam', report_return_to:return_to
      expect(last_response).to be_redirect
      expect(URI(last_response.location).request_uri).to eq('/review/1/canonical_documents')
    end
  end

  it 'links to reports from each stage and keeps exclusion specific to the chosen stage' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1,
                          report_type:'does_not_meet_criteria')
    %w[screening_title_abstract screening_references review_full_text].each do |stage|
      get "/review/1/administration/#{stage}"
      expect(last_response).to be_ok
      expect(last_response.body).to include("/review/1/administration_document_reports?stage=#{stage}")
      get '/review/1/administration_document_reports', stage:stage
      expect(last_response).to be_ok
      expect(last_response.body).to include("/resolution/review/1/canonical_document/1/stage/#{stage}/resolution")
    end

    other_stages=Resolution.where(systematic_review_id:1, canonical_document_id:1).
      exclude(stage:'review_full_text').all.map(&:values)
    post '/resolution/review/1/canonical_document/1/stage/review_full_text/resolution',
         resolution:'no', user_id:1
    expect(last_response).to be_ok
    expect(Resolution.where(systematic_review_id:1, canonical_document_id:1,
                            stage:'review_full_text').first.resolution).to eq('no')
    expect(Resolution.where(systematic_review_id:1, canonical_document_id:1).
      exclude(stage:'review_full_text').all.map(&:values)).to eq(other_stages)
  end

  it 'shows report reasons after canonical titles, combining users and omitting ignored reports' do
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:1,
                          report_type:'does_not_meet_criteria')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2,
                          report_type:'duplicate')
    DocumentReport.create(systematic_review_id:1, canonical_document_id:1, user_id:2,
                          report_type:'spam', status:'ignored')
    get '/review/1/canonical_documents', query:'Pager document 1'
    expect(last_response).to be_ok
    row=Nokogiri::HTML(last_response.body).at_css('#canonical-document-1')
    badge=row.at_css('.canonical-document-reported')
    expect(badge.text).to include('Reported:', 'Does not meet criteria', 'Duplicate Document')
    expect(badge.text).not_to include('Spam')
    expect(row.text.index('Pager document 1')).to be < row.text.index('Reported:')
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
