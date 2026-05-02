require 'json'

# @!group Document reports

put '/review/:sr_id/document_report/cd/:cd_id/user/:user_id/report_types' do |sr_id, cd_id, user_id|
  halt_unless_auth('review_analyze')

  @sr=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr

  @cd=CanonicalDocument[cd_id]
  raise Buhos::NoCdIdError, cd_id if !@cd

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
