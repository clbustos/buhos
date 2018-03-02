#
Sequel.migration do
  change do
    alter_table(:searches) do
      add_column :source, String, :null=>true
    end

  end
end