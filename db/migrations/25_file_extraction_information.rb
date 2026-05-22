# Files used as extraction guidelines by users.
Sequel.migration do
  change do
    create_table(:file_extraction_informations) do
      primary_key :id
      foreign_key :file_id, :files, :null=>false, :key=>[:id]
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      DateTime :created_at

      index [:file_id]
      index [:systematic_review_id]
      index [:canonical_document_id]
      index [:user_id]
    end
  end
end
