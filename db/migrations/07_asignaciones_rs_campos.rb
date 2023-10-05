# Agrega asignaciones y campos de llenado para revisión sistemática

Sequel.migration do
  change do
    create_table(:allocation_cds) do
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      String      :stage, :size=>32, :null=>false
      String      :instructions
      String      :status
      primary_key [:systematic_review_id, :canonical_document_id,:user_id, :stage]
    end
    create_table(:sr_fields) do
      primary_key :id
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      Integer :order
      String :name
      String :description
      String :type
      String :options, :text=>true
      unique [:systematic_review_id, :name]
    end
  end
end