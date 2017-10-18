# Agregamos columnas a los archivos, para su mejor manejo
Sequel.migration do
  change do
    alter_table(:archivos) do
      # Mïnimo número de referencias rtr para revisión de referencias
      add_column :paginas, Integer, default:nil
      add_column :titulo, String
    end
    alter_table(:archivos_rs) do
      add_column :funcion, String
    end
  end
end