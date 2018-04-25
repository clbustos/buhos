Sequel.migration do
  up do
    alter_table(:canonical_documents) do
      add_column :pmid, String, :null=>true
    end
    from(:canonical_documents).update(:pmid=>:pubmed)
    alter_table(:canonical_documents) do
      drop_column :pubmed
    end

    create_table(:pmc_summaries) do
      String :id, :primary_key => true
      String :xml, :text => true
      String :doi, :size => 255
    end
  end

  down do
    alter_table(:canonical_documents) do
      add_column :pubmed, String, :null=>true
    end
    from(:canonical_documents).update(:pubmed=>:pmid)
    alter_table(:canonical_documents) do
      drop_column :pmid
    end
    drop_table :pmc_summaries
  end

end