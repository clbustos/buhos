require 'json'

class DocumentReport < Sequel::Model(:sr_document_reports)
  plugin :validation_helpers
  plugin :dirty

  # Relaciones
  many_to_one :user
  many_to_one :systematic_review
  many_to_one :canonical_document

  # Tipos de reporte permitidos (opcional, para validación)
  CONFLICTING_RESOLUTION = 'conflicting_resolution'
  MISSING_FILE = 'missing_file'
  REPORT_TYPES = %w[duplicate ocr_error wrong_metadata missing_file spam other conflicting_resolution]
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

  def self.report_conflicting_resolution(systematic_review_id:, canonical_document_id:, user_id:)
    criteria={
      systematic_review_id:systematic_review_id,
      canonical_document_id:canonical_document_id,
      user_id:user_id,
      report_type:CONFLICTING_RESOLUTION
    }
    report=where(criteria).first

    if report
      report.update(status:'pending') unless report.status == 'pending'
      report
    else
      create(criteria.merge(status:'pending'))
    end
  end

  def self.resolve_conflicting_resolution(systematic_review_id:, canonical_document_id:)
    where(
      systematic_review_id:systematic_review_id,
      canonical_document_id:canonical_document_id,
      report_type:CONFLICTING_RESOLUTION,
      status:'pending'
    ).update(status:'resolved')
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
