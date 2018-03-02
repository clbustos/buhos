# Crea sistema de tags (códigos) para cada documento
# canónico. Cada familia de tag está cerrado en una revisión sistemática
# Después podríamos pensar en un sistema de copia de tags de una revisión a otra


Sequel.migration do
  transaction
  change do
    # tag -> familia_tag (depende de revision) -> Si no tiene familia, es libre.
    # cd_tags -> son los tags asignados a un cd. Anoto el usuario que lo puso.
    create_table(:tags) do
      primary_key :id
      String :text
    end
    create_table(:t_classes) do
      primary_key :id
      String :name
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      String :stage, :size=>50, :null=>true
      String :type,  :null=>true
    end

    create_table(:tag_in_classes) do
      foreign_key :tc_id, :t_classes, :null=>false, :key=>[:id]
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      primary_key [:tc_id, :tag_id]
    end
    create_table(:tag_in_cds) do
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      String :decision
      String :commentary, :text=>true
      primary_key [:tag_id, :canonical_document_id, :user_id,:systematic_review_id]
    end
    create_table(:tag_bw_cds) do
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      foreign_key :cd_start, :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :cd_end,   :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      String :decision
      String :commentary, :text=>true
      primary_key [:tag_id, :cd_start , :cd_end, :user_id, :systematic_review_id]
    end
  end
end