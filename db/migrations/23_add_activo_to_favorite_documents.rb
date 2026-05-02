Sequel.migration do
  up do
    alter_table(:favorite_documents) do
      add_column :activo, TrueClass, default: true, null: false
    end
  end

  down do
    alter_table(:favorite_documents) do
      drop_column :activo
    end
  end
end
