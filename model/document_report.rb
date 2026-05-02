require 'json'

class DocumentReport < Sequel::Model(:sr_document_reports)
  plugin :validation_helpers
  plugin :dirty

  # Relaciones
  many_to_one :user
  many_to_one :systematic_review
  many_to_one :canonical_document

  # Tipos de reporte permitidos (opcional, para validación)
  REPORT_TYPES = %w[duplicate ocr_error wrong_metadata spam other]
  STATUSES     = %w[pending resolved ignored]

  def self.report_type_options
    REPORT_TYPES.inject({}) do |options, report_type|
      options[report_type]=I18n.t("document_reports.#{report_type}")
      options
    end
  end

  def self.report_type_source
    JSON.generate(report_type_options.map {|key, value| {value:key, text:value}})
  end

  def before_validation
    self.status ||= 'pending'
    super
  end

  def validate
    super
    validates_presence [:systematic_review_id, :report_type, :user_id, :canonical_document_id]
    validates_includes REPORT_TYPES, :report_type
    validates_includes STATUSES, :status
    # Unicidad: un usuario no reporta el mismo error dos veces para el mismo documento
    validates_unique([:systematic_review_id, :canonical_document_id, :user_id, :report_type])
  end

  # Hooks para manejar fechas de resolución
  def before_save
    if column_changed?(:status) && status == 'resolved'
      self.resolved_at = DateTime.now
    end
    super
  end
end
