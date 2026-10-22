require 'json'

# @!group Document reports

post '/review/:sr_id/document_reports/batch' do |sr_id|
  halt_unless_auth('review_admin')
  review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id unless review
  report_type=params['report_type']
  halt 400 unless DocumentReport::REPORT_TYPES.include?(report_type)
  selection=params['canonical_document']
  halt 400 unless selection.is_a?(Hash) && !selection.empty?
  cd_ids=selection.keys.map(&:to_i).uniq
  valid_ids=review.canonical_documents.where(Sequel[:canonical_documents][:id]=>cd_ids).
    select_map(Sequel[:canonical_documents][:id]).uniq
  halt 403 unless valid_ids.sort == cd_ids.sort

  $db.transaction do
    cd_ids.each do |cd_id|
      criteria={systematic_review_id:review.id, canonical_document_id:cd_id,
                user_id:session['user_id'], report_type:report_type}
      report=DocumentReport.where(criteria).first
      if report
        report.update(status:'pending', resolved_at:nil)
      else
        DocumentReport.create(criteria)
      end
    end
  end
  redirect url("/review/#{review.id}/administration_document_reports")
end

put '/review/:sr_id/document_report/cd/:cd_id/user/:user_id/report_types' do |sr_id, cd_id, user_id|
  halt_unless_auth_any('review_analyze', 'review_admin')
  halt 403 unless is_session_user(user_id)

  @sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd
  halt 403 unless @sr.canonical_documents.where(Sequel[:canonical_documents][:id]=>cd_id.to_i).count > 0

  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user

  selected_types=Array(params['value']).flat_map {|value| value.to_s.split(',')}.
    map(&:strip).
    reject(&:empty?) & DocumentReport::REPORT_TYPES

  criteria={
    systematic_review_id:sr_id,
    canonical_document_id:cd_id,
    user_id:user_id
  }

  $db.transaction do
    reports_scope=DocumentReport.where(criteria).map(:report_type)
    reports_scope||=[]
    to_add=selected_types-reports_scope
    to_delete=reports_scope-selected_types

    to_add.each do |report_type|
      DocumentReport.insert(criteria.merge(report_type: report_type))
    end

    to_delete.each do |report_type|
      DocumentReport.where(criteria.merge(report_type: report_type)).delete
    end
  end

  content_type :json
  JSON.generate(selected:selected_types)
end

# @!endgroup
