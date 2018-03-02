# Agrega asignaciones de documentos canónicos a users.
# Debería hacerse después de la selección por abstract y references...

Sequel.migration do
  change do
    create_table(:useless_cd_allocations) do
      # Mïnimo número de references rtr para revisión de references
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
      String :commentary, :text=>true

      primary_key [:systematic_review_id, :user_id, :canonical_document_id]

      index [:canonical_document_id]
      index [:systematic_review_id]
      index [:systematic_review_id, :user_id]
      index [:user_id]
    end
  end
end