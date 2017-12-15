# Agrega archivos

Sequel.migration do
  change do
   create_table(:archivos) do
     primary_key :id
     String :archivo_tipo, :size=>50
     String :archivo_nombre, :size=>128
     String :archivo_ruta, :size=>255
     String :sha256, :size=>64
     unique [:sha256]
   end
   create_table(:archivos_rs) do
     foreign_key :archivo_id, :archivos, :null=>false, :key=>[:id]
     foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
     primary_key [:archivo_id, :revision_sistematica_id]
   end
   create_table(:archivos_cds) do
     foreign_key :archivo_id, :archivos, :null=>false, :key=>[:id]
     foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
     primary_key [:canonico_documento_id, :archivo_id]
   end
  end
end