#
Sequel.migration do
  change do
    alter_table(:users) do
      add_column :language, String, :default=>'en'
    end
    alter_table(:searches) do
      add_foreign_key :user_id, :users, :null=>false, :key=>[:id], :default=>1
      add_column :valid, TrueClass, :default=>nil, :null=>true
    end

  end
end