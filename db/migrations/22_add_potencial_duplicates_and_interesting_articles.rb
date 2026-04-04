Sequel.migration do
  up do
    # 1. Tabla para reportar UN documento como posible duplicado
    # El usuario marca el documento 'A' y el sistema luego permite compararlo
    create_table?(:sr_reported_duplicates) do
      primary_key :id
      foreign_key :systematic_review_id, :systematic_reviews, null: false, key: [:id], on_delete: :cascade
      foreign_key :canonical_document_id, :canonical_documents, null: false, key: [:id], on_delete: :cascade
      foreign_key :user_id, :users, null: false, key: [:id]

      String :commentary, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      # Un usuario solo reporta una vez el mismo documento en la misma SR
      index [:systematic_review_id, :canonical_document_id, :user_id], unique: true
    end

    # 2. Tabla para documentos de interés (favoritos/destacados)
    create_table?(:sr_interesting_documents) do
      foreign_key :systematic_review_id, :systematic_reviews, null: false, key: [:id], on_delete: :cascade
      foreign_key :canonical_document_id, :canonical_documents, null: false, key: [:id], on_delete: :cascade
      foreign_key :user_id, :users, null: false, key: [:id]

      String :commentary, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      primary_key [:systematic_review_id, :canonical_document_id, :user_id]

      index [:user_id]
    end
  end

  down do
    drop_table(:sr_interesting_documents)
    drop_table(:sr_reported_duplicates)
  end
end