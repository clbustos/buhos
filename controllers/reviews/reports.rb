# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group report
#

# Provide a report
# @see ReportBuilder.get_report
get '/review/:sr_id/report/:type/:format' do |sr_id,type,format|
  halt_unless_auth('review_view')
  @sr=SystematicReview[sr_id]
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