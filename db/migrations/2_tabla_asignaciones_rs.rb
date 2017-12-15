# Agrega asignaciones de documentos canónicos a usuarios.
# Debería hacerse después de la selección por abstract y referencias...

Sequel.migration do
  change do
    create_table(:cd_asignaciones) do
      # Mïnimo número de referencias rtr para revisión de referencias
      foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
      foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
      foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
      String :comentario, :text=>true

      primary_key [:revision_sistematica_id, :usuario_id, :canonico_documento_id]

      index [:canonico_documento_id]
      index [:revision_sistematica_id]
      index [:revision_sistematica_id, :usuario_id]
      index [:usuario_id]
    end
  end
end