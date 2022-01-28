Sequel.migration do
  up do
    alter_table(:canonical_documents) do
      add_column :semantic_scholar_id, String, :null=>true
    end
    create_table(:semantic_scholar_papers) do
      String :id, :primary_key => true
      String :json, :text => true
      String :doi, :size => 255
    end
  end

  down do
   alter_table(:canonical_documents) do
      drop_column :semantic_scholar_id
    end
    drop_table :semantic_scholar_papers
  end

end