# Agregamos columnas a los archivos, para su mejor manejo
Sequel.migration do
  change do
    alter_table(:usuarios) do
      # Mïnimo número de referencias rtr para revisión de referencias
      add_column :language, String, :default=>'en'
    end
  end
end