require_relative 'init.rb'



$db.create_table? :roles do
   String :id, :size=>50, :primary_key=>true
  String :descripcion
end

$db.create_table? :usuarios do
  primary_key :id
  String :login,:null=>false
  String :nombre
  String :password,:null=>false
  foreign_key :rol_id, :roles, :type=>String, :size=>50, :null=>false
  Fixnum :activa
end


$db.create_table? :grupos do
  primary_key :id
  foreign_key :administrador_grupo, :usuarios, :null=>false
  String :description
end

$db.create_join_table?(:usuario_id=>:usuarios,:grupo_id=>:grupos)

$db.create_table? :revisiones_sistematicas do
  primary_key :id
  String :nombre
  Date :fecha_inicio
  String :descripcion, :text=>true
  String :objetivos, :text=>true
  Fixnum :agno_inicio
  Fixnum :agno_termino
  String :palabras_claves
  foreign_key :grupo_id, :grupos, :null=>false
  foreign_key :administrador_revision, :usuarios, :null=>false
end

$db.create_table? :bases_bibliograficas do
  primary_key :id
  String :nombre
  String :description, :text=>true
end


$db.create_table? :canonicos_documentos do
  primary_key :id
  String :tipo
  String :titulo, :text=>true
  String :autores, :text=>true
  String :fecha
  String :journal, :text=>true
  String :volumen
  String :numero
  String :paginas
  String :nombre_libro, :text=>true
  String :editores, :text=>true
  String :conferencia, :text=>true
  String :lugar
  String :editorial
  String :doi
  String :pubmed
end

$db.create_table? :canonicos_autores do
  primary_key :id
  String :primer_nombre
  String :segundo_nombre
  String :email
  String :scopus_id
  String :wos_id
end

$db.create_table? :canonicos_documentos_autores do
  foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false
  foreign_key :canonico_autor_id, :canonicos_autores, :null=>false
  String :filiacion
  String :email
  primary_key [:canonico_documento_id, :canonico_autor_id]
end

$db.create_table? :busquedas do
   primary_key :id
   foreign_key :revision_sistematica_id  ,:revisiones_sistematicas, :null=>false, :index=>true
   foreign_key :base_bibliografica_id    ,:bases_bibliograficas, :null=>false
   Date :fecha, :index=>true
   String :criterio_busqueda, :text=>true
   String :descripcion, :text=>true

end

$db.create_table? :registros do
  primary_key :id
  foreign_key :base_bibliografica_id    ,:bases_bibliograficas, :null=>false
  String :base_datos_id
  String :tipo
  String :titulo, :text=>true
  String :autores, :text=>true
  String :fecha
  String :journal, :text=>true
  String :volumen
  String :numero
  String :paginas
  String :nombre_libro, :text=>true
  String :editores, :text=>true
  String :conferencia, :text=>true
  String :lugar
  String :editorial
  String :doi
  String :pmid
  String :arxiv_id
  foreign_key :canonico_documento_id ,:canonicos_documentos, :null=>true
end


$db.create_join_table?(:busqueda_id=>:busquedas,:registro_id=>:registros)




$db.create_table? :permisos do
  String :id, :size=>50, :primary_key=>true
  String :descripcion
end


$db.create_table? :configuraciones do
  String :id,  :primary_key=>true
  String :valor, :text=>true
end

$db.create_table? :permisos_roles do
   foreign_key :permiso_id  ,:permisos, :type=>String, :size=>50, :null=>false
   foreign_key :rol_id      ,:roles, :type=>String, :size=>50, :null=>false
   primary_key [:permiso_id,:rol_id]
   index [:permiso_id,:rol_id]

end

