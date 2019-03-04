Sequel.migration do
  change do
    alter_table(:users) do
      add_index :login, unique: true
    end
  end
end