#
Sequel.migration do
  change do
    alter_table(:canonicos_documentos) do
      add_column :generic_id, String, :null=>true
    end
  end
end