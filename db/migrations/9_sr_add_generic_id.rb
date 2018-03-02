#
Sequel.migration do
  change do
    alter_table(:canonical_documents) do
      add_column :generic_id, String, :null=>true
    end
  end
end