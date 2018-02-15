#
Sequel.migration do
  change do
    alter_table(:busquedas) do
      add_column :source, String, :null=>true
    end

  end
end