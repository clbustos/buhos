get '/review/:sr_id/report/:type/:format' do |sr_id,type,format|
  halt_unless_auth('review_view')
  @sr=Revision_Sistematica[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@sr
  @type=type
  return 404 if @sr.nil?
  @report=ReportBuilder.get_report(@sr,@type, self)
  if format=='html'
    haml "/reports/#{type.downcase}".to_sym
  else
    @report.output(format)
  end
end