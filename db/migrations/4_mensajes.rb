# Agrega asignaciones de documentos canónicos a usuarios.
# Debería hacerse después de la selección por abstract y referencias...

Sequel.migration do
  change do
    create_table(:mensajes) do
      # Mïnimo número de referencias rtr para revisión de referencias
      primary_key :id
      foreign_key :usuario_desde, :usuarios, :null=>false, :key=>[:id]
      foreign_key :usuario_hacia, :usuarios, :null=>false, :key=>[:id]
      foreign_key :respuesta_a,   :mensajes, :null=>true, :key=>[:id]
      DateTime :tiempo
      String :asunto
      String :texto, :text=>true
      Bool :visto
      index [:usuario_desde]
      index [:usuario_hacia]
    end
    create_table(:mensajes_rs) do
      primary_key :id
      foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
      foreign_key :usuario_desde, :usuarios, :null=>false, :key=>[:id]
      foreign_key :respuesta_a,   :mensajes_rs, :null=>true, :key=>[:id]
      DateTime :tiempo
      String :asunto
      String :texto, :text=>true
    end
    create_table(:mensajes_rs_vistos) do
      foreign_key :m_rs_id,   :mensajes_rs, :null=>false, :key=>[:id]
      foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
      Bool :visto
      primary_key [:m_rs_id, :usuario_id]
    end
  end
end