# Agrega files

Sequel.migration do
  change do
   create_table(:files) do
     primary_key :id
     String :filetype, :size=>50
     String :filename, :size=>128
     String :file_path, :size=>255
     String :sha256, :size=>64
     unique [:sha256]
   end
   create_table(:file_srs) do
     foreign_key :file_id, :files, :null=>false, :key=>[:id]
     foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
     primary_key [:file_id, :systematic_review_id]
   end
   create_table(:file_cds) do
     foreign_key :file_id, :files, :null=>false, :key=>[:id]
     foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
     primary_key [:canonical_document_id, :file_id]
   end
  end
end