Sequel.migration do
  up do
    alter_table(:canonical_documents) do
      add_column :pubmed_id, String, :null=>true
    end
    run "INSERT INTO bibliographic_databases (name) VALUES ('pubmed') "

  end

  down do
    alter_table(:canonical_documents) do
      drop_column :pubmed_id
    end
    from(:bibliographic_databases).where(:name=>"pubmed").delete()

  end

end