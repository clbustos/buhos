module ReportBuilder
  def self.get_report(sr,type,app)
    klass="#{type.capitalize}Report".to_sym
    ReportBuilder.const_get(klass).send(:new, sr,app)
  end
end


require_relative "report_builder/prisma_report"
require_relative "report_builder/fulltext_report"
require_relative "report_builder/process_report"
