#
Sequel.migration do
  change do
    alter_table(:revisiones_sistematicas) do
      add_column :generic_id, String, :null=>true
    end
  end
end