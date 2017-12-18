#
Sequel.migration do
  change do
    alter_table(:usuarios) do
      add_column :language, String, :default=>'en'
    end
    alter_table(:busquedas) do
      add_foreign_key :user_id, :usuarios, :null=>false, :key=>[:id], :default=>1
      add_column :review_ready, TrueClass, :default=>false, :null=>false
    end

  end
end