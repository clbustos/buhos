Sequel.migration do
  up do
    # 1. Tabla de Grupos de Favoritos
    # Colecciones creadas por el usuario (ej: "Lectura obligatoria", "Tesis 2026")
    create_table?(:favorite_groups) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade

      String :name, null: false
      String :description, text: true

      # Usamos TrueClass para un manejo booleano nativo en Ruby
      TrueClass :is_public, default: false, null: false

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      # Un usuario no puede repetir nombres de grupos
      index [:user_id, :name], unique: true
    end

    # 2. Tabla de Documentos Favoritos
    # Relaciona un documento con una revisión, un usuario y opcionalmente un grupo
    create_table?(:favorite_documents) do
      foreign_key :systematic_review_id, :systematic_reviews, null: false, on_delete: :cascade
      foreign_key :canonical_document_id, :canonical_documents, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false, on_delete: :cascade

      # Referencia al grupo personal (opcional)
      foreign_key :group_id, :favorite_groups, null: true, on_delete: :set_null

      String :commentary, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      # PK Compuesta: permite al usuario tener el mismo documento en diferentes grupos
      primary_key [:systematic_review_id, :canonical_document_id, :user_id, :group_id]

      index :group_id
      index :user_id
    end

    # 3. Tabla de Reporte de Duplicados
    create_table?(:sr_reported_duplicates) do
      primary_key :id
      foreign_key :systematic_review_id, :systematic_reviews, null: false, on_delete: :cascade
      foreign_key :canonical_document_id, :canonical_documents, null: false, on_delete: :cascade
      foreign_key :user_id, :users, null: false

      String :commentary, text: true
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP

      index [:systematic_review_id, :canonical_document_id, :user_id], unique: true, name: :srrd_unique_report
    end
  end

  down do
    drop_table(:sr_reported_duplicates)
    drop_table(:favorite_documents)
    drop_table(:favorite_groups)
  end
end