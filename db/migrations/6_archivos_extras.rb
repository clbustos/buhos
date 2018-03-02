# Agregamos columnas a los files, para su mejor manejo
Sequel.migration do
  change do
    alter_table(:files) do
      # Mïnimo número de references rtr para revisión de references
      add_column :pages, Integer, default:nil
      add_column :title, String
    end
    alter_table(:file_cds) do
      add_column :not_consider, TrueClass, :default=>false
    end
    alter_table(:file_srs) do
      add_column :not_consider, TrueClass, :default=>false
    end
  end
end