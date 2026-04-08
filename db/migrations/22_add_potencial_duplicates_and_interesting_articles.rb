Sequel.migration do
  up do
    # 1. Grupos de Favoritos (Colecciones del usuario)
    create_table?(:favorite_groups) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade

      String :name, null: false
      String :description, text: true
      TrueClass :is_public, default: false, null: false

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      index [:user_id, :name], unique: true
    end

    # 2. Documentos Favoritos
    create_table?(:favorite_documents) do
      foreign_key :canonical_document_id, :canonical_documents, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      foreign_key :group_id, :favorite_groups, null: true, on_delete: :set_null

      String :commentary, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      primary_key [ :canonical_document_id, :user_id]
      index :group_id
    end

    # 3. Reportes Generales de Documentos
    create_table?(:sr_document_reports) do
      primary_key :id
      foreign_key :systematic_review_id, :systematic_reviews, null: false, on_delete: :cascade
      foreign_key :canonical_document_id, :canonical_documents, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false

      # Ejemplos: 'duplicate', 'ocr_error', 'wrong_metadata', 'spam'
      String :report_type, null: false
      String :commentary, text: true

      # Gestión del reporte
      String :status, default: 'pending', null: false # 'pending', 'resolved', 'ignored'
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :resolved_at, null: true

      # Un usuario puede reportar distintas cosas, pero no repetir el mismo tipo de reporte
      index [:systematic_review_id, :canonical_document_id, :user_id, :report_type],
            unique: true,
            name: :srdr_unique_report_type
    end
  end

  down do
    drop_table(:sr_document_reports)
    drop_table(:favorite_documents)
    drop_table(:favorite_groups)
  end
end