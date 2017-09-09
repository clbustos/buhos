require_relative 'init.rb'

if(ENV['CREATE_SCHEMA'])

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

# Taxonomía de revisiones sistemáticas

["foco","objetivo","perspectiva","cobertura","organizacion","destinario"].each do |v|
  $db.create_table? "trs_#{v}".to_sym do
    primary_key :id
    String :name
  end
end


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
  
  foreign_key :trs_foco_id, :trs_foco, :null=>false
  foreign_key :trs_objetivo_id, :trs_objetivo, :null=>false
  foreign_key :trs_perspectiva_id, :trs_perspectiva, :null=>false
  foreign_key :trs_cobertura_id, :trs_cobertura, :null=>false
  foreign_key :trs_organizacion_id, :trs_organizacion, :null=>false
  foreign_key :trs_destinatario_id, :trs_destinario, :null=>false
  
end

$db.create_table? :bases_bibliograficas do
  primary_key :id
  String :nombre
  String :description, :text=>true
end




$db.create_table? :canonicos_documentos do
  primary_key :id
  String :type
  String :title, :text=>true
  String :author, :text=>true
  String :date
  String :journal, :text=>true
  String :volume
  String :number
  String :pages
  String :book_name, :text=>true
  String :editors, :text=>true
  String :proceedings, :text=>true
  String :place
  String :editorial
  String :doi
  String :pubmed
  String :wos_id, :size=>32
  String :scopus_id
  String :ebscohost_id
  Integer :year
  String :journal_abbr, :size=>32
  String :abstract, :text=>true
  String :url, :text => true
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
  String :uid
  String :title, :text=>true
  String :author, :text=>true
  String :date
  String :journal, :text=>true
  String :volume
  String :number
  String :pages
  String :book_name, :text=>true
  String :editors, :text=>true
  String :proceedings, :text=>true
  String :place
  String :editorial
  String :doi
  String :pmid
  String :arxiv_id
  Integer :year
  String :journal_abbr, :size=>32
  String :abstract, :text=>true
  String :url, :text => true
  foreign_key :canonico_documento_id ,:canonicos_documentos, :null=>true
end

$db.create_table? :referencias do
  String :id, :primary_key=>true
  String :texto, :text=>true
  String :doi

  foreign_key :canonico_documento_id ,:canonicos_documentos, :null=>true
end


  $db.create_join_table?(:busqueda_id=>:busquedas,:registro_id=>:registros)
  $db.create_join_table?(:referencia_id=>{:table=>:referencias, :type=>String},:registro_id=>:registros)


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

$db.create_table? :crossref_queries do
  String :id, :size=>100, :primary_key=>true
  String :query, :text=>true
  String :json, :text=>true
end


  $db.create_table? :crossref_dois do
    String :doi, :size=>100, :primary_key=>true
    String :bibtex, :text=>true
    String :json, :text=>true
  end

  $db.create_table? :scopus_abstracts do
    String :id, :primary_key => true
    String :xml, :text => true
    String :doi
  end


  $db.create_table? :decisiones do
    foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null => false, :index => true
    foreign_key :usuario_id, :usuarios, :null => false, :index => true
    foreign_key :canonico_documento_id, :canonicos_documentos, :null => false, :index => true
    String :etapa, :null => false
    String :decision
    String :comentario, :text => true
    primary_key [:revision_sistematica_id, :usuario_id, :canonico_documento_id, :etapa]
    index [:revision_sistematica_id, :usuario_id, :etapa]
  end

end

