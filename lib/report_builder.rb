# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Common interface to create reports.
#
# On route '/review/:sr_id/report/:type/:format'
# ReportBuilder is called with
#     @report=ReportBuilder.get_report(@sr,@type, self)
# @sr is a {Systematic Review}, type represent the type of report
# and self is the app sinatra object.
# Class to obtain report is obtained capitalizing type and adding 'Report'
# So, 'fulltext' instantiate a ReportBuilder::FullTextReport, with params
# sr and app.
#
# If format is html, @report object will be sent to '/views/report/<type>.haml' haml template.
#
# If not, {.output} will be called
#
module ReportBuilder
  def self.get_report(sr,type,app)
    klass="#{type.capitalize}Report".to_sym
    ReportBuilder.const_get(klass).send(:new, sr,app)
  end

  # Abstract interface for reports.
  # Note that we change to name to not instantiate this
  # if an 'Abstract' report be created on the future
  module ReportAbstract
    # A {SystematicReview} object
    attr_reader :sr
    # A Sinatra::Base object.
    attr_reader :app
    def output(format)
      send("output_#{format}".to_sym)
    end
  end
end


require_relative "report_builder/prisma_report"
require_relative "report_builder/fulltext_report"
require_relative "report_builder/process_report"
