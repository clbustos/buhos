Sequel.migration do
  change do

    create_table(:criteria) do
      primary_key :id
      String :text
    end

    create_table(:sr_criteria) do
      foreign_key :criterion_id, :criteria, :null=>false, :key=>[:id], :default=>nil
      foreign_key :systematic_review_id, :systematic_reviews, :null => false, :key => [:id]
      String :criteria_type
      primary_key [:criterion_id, :systematic_review_id]
    end

    create_table(:cd_criteria) do
      foreign_key :criterion_id, :criteria, :null=>false, :key=>[:id], :default=>nil
      foreign_key :canonical_document_id, :canonical_documents, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      foreign_key :systematic_review_id, :systematic_reviews, :null => false, :key => [:id]
      Bool :viewed
      primary_key [:criterion_id, :canonical_document_id, :user_id, :systematic_review_id]
    end

  end
end