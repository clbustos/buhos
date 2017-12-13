# Crea sistema de tags (códigos) para cada documento
# canónico. Cada familia de tag está cerrado en una revisión sistemática
# Después podríamos pensar en un sistema de copia de tags de una revisión a otra


Sequel.migration do
  transaction
  change do
    # tag -> familia_tag (depende de revision) -> Si no tiene familia, es libre.
    # cd_tags -> son los tags asignados a un cd. Anoto el usuario que lo puso.
    create_table(:tags) do
      primary_key :id
      String :texto
    end
    create_table(:t_clases) do
      primary_key :id
      String :nombre
      foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
      String :etapa, :size=>50, :null=>true
      String :tipo,  :null=>true
    end

    create_table(:tags_en_clases) do
      foreign_key :tc_id, :t_clases, :null=>false, :key=>[:id]
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      primary_key [:tc_id, :tag_id]
    end
    create_table(:tags_en_cds) do
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
      foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
      foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
      String :decision
      String :comentario, :text=>true
      primary_key [:tag_id, :canonico_documento_id, :usuario_id,:revision_sistematica_id]
    end
    create_table(:tags_en_referencias_entre_cn) do
      foreign_key :tag_id, :tags, :null=>false, :key=>[:id]
      foreign_key :cd_origen, :canonicos_documentos, :null=>false, :key=>[:id]
      foreign_key :cd_destino, :canonicos_documentos, :null=>false, :key=>[:id]
      foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
      foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
      String :decision
      String :comentario, :text=>true
      primary_key [:tag_id, :cd_origen, :cd_destino, :usuario_id,:revision_sistematica_id]
    end
  end
end