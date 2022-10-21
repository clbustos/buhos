Sequel.migration do
  up do
    alter_table(:canonical_documents) do
      add_column :arxiv_id, String , :size => 255
    end
    alter_table(:records)   do
      add_column :pubmed_id, String
      add_column :wos_id, String, :size => 32
      add_column :scopus_id, String , :size => 255
      add_column :ebscohost_id, String, :size => 255
      add_column :scielo_id, String , :size => 255
      add_column :refworks_id, String , :size => 255
    end
  end

  down do
   alter_table(:canonical_documents) do
      drop_column :arxiv_id
   end
   alter_table(:records) do
     drop_column :pubmed_id
     drop_column :wos_id
     drop_column :scopus_id
     drop_column :ebscohost_id
     drop_column :scielo_id
     drop_column :refworks_id
   end
  end

end