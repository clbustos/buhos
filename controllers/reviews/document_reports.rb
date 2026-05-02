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
    reports_scope=DocumentReport.where(criteria)
    if selected_types.empty?
      reports_scope.delete
    else
      reports_scope.exclude(report_type:selected_types).delete
    end

    selected_types.each do |report_type|
      report=DocumentReport.where(criteria.merge(report_type:report_type)).first
      if report
        report.update(status:'pending')
      else
        DocumentReport.create(criteria.merge(report_type:report_type))
      end
    end
  end

  content_type :json
  JSON.generate(selected:selected_types)
end

# @!endgroup
