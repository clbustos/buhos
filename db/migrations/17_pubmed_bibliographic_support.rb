Sequel.migration do
  up do
    alter_table(:canonical_documents) do
      add_column :pubmed_id, String, :null=>true
    end

  end

  down do
    alter_table(:canonical_documents) do
      drop_column :pubmed_id
    end

  end

end
