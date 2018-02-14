get '/revision/:sr_id/reporte/:type/:format' do |sr_id,type,format|

  @sr=Revision_Sistematica[sr_id]
  @type=type
  return 404 if @sr.nil?
  @report=ReportBuilder.get_report(@sr,@type, self)
  if format=='html'
    haml "/reportes/#{type.downcase}".to_sym
  else
    @report.output(format)
  end
end