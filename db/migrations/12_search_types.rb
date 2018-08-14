Sequel.migration do
  change do
    alter_table(:searches) do
      add_column :search_type, String, :null=>false, :default=>"manual"
    end
    alter_table(:records_searches) do
      add_foreign_key :file_id, :files, :null=>true, :key=>[:id], :default=>nil
    end
  end
end