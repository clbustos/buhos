require_relative 'init.rb'

if(ENV['CREATE_SCHEMA'])

  $db.create_table? :roles do
    String :id, :size=>50, :primary_key=>true
    String :descripcion
  end

  $db.create_table? :usuarios do
    primary_key :id
    String :login, :size=>255, :null=>false
    String :nombre, :size=>255
    String :password, :size=>255, :null=>false
    foreign_key :rol_id, :roles, :type=>String, :size=>50, :null=>false, :key=>[:id]
    Integer :activa
  end

  
$db.create_table? :grupos do
    primary_key :id
    foreign_key :administrador_grupo, :usuarios, :null=>false, :key=>[:id]
    String :description, :text=>true
    String :name, :size=>255, :null=>false
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
    String :nombre, :size=>255
    Date :fecha_inicio
    String :descripcion, :text=>true
    String :objetivos, :text=>true
    Integer :agno_inicio
    Integer :agno_termino
    String :palabras_claves, :size=>255
    foreign_key :grupo_id, :grupos, :null=>false, :key=>[:id]
    foreign_key :administrador_revision, :usuarios, :key=>[:id]
    foreign_key :trs_foco_id, :trs_focos, :null=>false, :key=>[:id]
    foreign_key :trs_objetivo_id, :trs_objetivos, :null=>false, :key=>[:id]
    foreign_key :trs_perspectiva_id, :trs_perspectivas, :null=>false, :key=>[:id]
    foreign_key :trs_cobertura_id, :trs_coberturas, :null=>false, :key=>[:id]
    foreign_key :trs_organizacion_id, :trs_organizaciones, :null=>false, :key=>[:id]
    foreign_key :trs_destinatario_id, :trs_destinatarios, :null=>false, :key=>[:id]
    TrueClass :activa, :default=>true, :null=>false
    String :etapa, :default=>"busqueda", :size=>32, :null=>false

    index [:administrador_revision], :name=>:administrador_revision
    index [:grupo_id], :name=>:grupo_id
    index [:trs_cobertura_id], :name=>:trs_cobertura_id
    index [:trs_destinatario_id], :name=>:trs_destinatario_id
    index [:trs_foco_id], :name=>:trs_foco_id
    index [:trs_objetivo_id], :name=>:trs_objetivo_id
    index [:trs_organizacion_id], :name=>:trs_organizacion_id
    index [:trs_perspectiva_id], :name=>:trs_perspectiva_id
  end

  $db.create_table? :bases_bibliograficas do
    primary_key :id
    String :nombre, :size=>255
    String :description, :text=>true
  end


  $db.create_table? :canonicos_documentos do
    primary_key :id
    String :type, :size=>255
    String :title, :text=>true
    String :author, :text=>true
    String :date, :size=>255
    String :journal, :text=>true
    String :volume, :size=>255
    String :number, :size=>255
    String :pages, :size=>255
    String :book_name, :text=>true
    String :editors, :text=>true
    String :proceedings, :text=>true
    String :place, :size=>255
    String :editorial, :size=>255
    String :doi, :size=>255
    String :pubmed, :size=>255
    String :wos_id, :size=>32
    String :scopus_id, :size=>255
    String :ebscohost_id, :size=>255
    Integer :year, :null=>false
    String :journal_abbr, :size=>100
    String :abstract, :text=>true
    Integer :duplicated
    String :url, :text=>true
    String :scielo_id, :size=>255
    String :refworks_id, :size=>255, :null=>false
  end

  $db.create_table? :canonicos_autores  do
    primary_key :id
    String :primer_nombre, :size=>255
    String :segundo_nombre, :size=>255
    String :email, :size=>255
    String :scopus_id, :size=>255
    String :wos_id, :size=>255
  end

  $db.create_table? :canonicos_documentos_autores do
    foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
    foreign_key :canonico_autor_id, :canonicos_autores, :null=>false, :key=>[:id]
    String :filiacion, :size=>255
    String :email, :size=>255
    index [:canonico_autor_id], :name=>:canonico_autor_id
    primary_key [:canonico_documento_id, :canonico_autor_id]
  end

  $db.create_table? :busquedas do
    primary_key :id
    foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
    foreign_key :base_bibliografica_id, :bases_bibliograficas, :null=>false, :key=>[:id]
    Date :fecha
    String :criterio_busqueda, :text=>true
    String :descripcion, :text=>true
    File :archivo_cuerpo
    String :archivo_tipo, :size=>50
    String :archivo_nombre, :size=>128

    index [:base_bibliografica_id], :name=>:base_bibliografica_id
    index [:fecha]
    index [:revision_sistematica_id]
  end

 $db.create_table? :registros do
    primary_key :id
    foreign_key :base_bibliografica_id, :bases_bibliograficas, :null=>false, :key=>[:id]
    String :uid, :size=>255
    String :type, :size=>255
    String :title, :text=>true
    String :author, :text=>true
    String :date, :size=>255
    String :journal, :text=>true
    String :volume, :size=>255
    String :number, :size=>255
    String :pages, :size=>255
    String :book_name, :text=>true
    String :editors, :text=>true
    String :proceedings, :text=>true
    String :place, :size=>255
    String :publisher, :size=>255
    String :doi, :size=>255
    String :pmid, :size=>255
    String :arxiv_id, :size=>255
    foreign_key :canonico_documento_id, :canonicos_documentos, :key=>[:id]
    String :journal_abbr, :size=>128
    Integer :year, :null=>false
    String :abstract, :text=>true
    String :url, :text=>true

    index [:base_bibliografica_id], :name=>:base_bibliografica_id
    index [:canonico_documento_id], :name=>:canonico_documento_id
  end

  $db.create_table? :referencias do
  String :id, :primary_key=>true
    String :texto, :text=>true
    String :doi, :size=>255
    foreign_key :canonico_documento_id, :canonicos_documentos, :key=>[:id]
    index [:canonico_documento_id], :name=>:canonico_documento_id
  end

  $db.create_join_table?(:busqueda_id=>:busquedas,:registro_id=>:registros)
  $db.create_join_table?(:referencia_id=>{:table=>:referencias, :type=>String},:registro_id=>:registros)

  $db.create_table? :permisos do
  String :id, :size=>50, :primary_key=>true
    String :descripcion, :size=>255
  end


  $db.create_table? :configuraciones do
  String :id,  :primary_key=>true
    String :valor, :text=>true
  end

  $db.create_table? :permisos_roles do
    foreign_key :permiso_id, :permisos, :type=>String, :size=>50, :null=>false, :key=>[:id]
    foreign_key :rol_id, :roles, :type=>String, :size=>50, :null=>false, :key=>[:id]

    primary_key [:permiso_id, :rol_id]

    index [:permiso_id, :rol_id]
    index [:rol_id], :name=>:rol_id
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
    String :xml, :text=>true
    String :doi, :size=>255
  end

  $db.create_table? :decisiones do
    foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
    foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
    foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
    String :etapa, :size=>255, :null=>false
    String :decision, :size=>255
    String :comentario, :text=>true

    primary_key [:revision_sistematica_id, :usuario_id, :canonico_documento_id, :etapa]

    index [:canonico_documento_id]
    index [:revision_sistematica_id]
    index [:revision_sistematica_id, :usuario_id, :etapa]
    index [:usuario_id]
  end
  $db.create_table? :resoluciones do
    foreign_key :revision_sistematica_id, :revisiones_sistematicas, :null=>false, :key=>[:id]
    foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
    foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
    String :etapa, :size=>255, :null=>false
    String :resolucion, :size=>255
    String :comentario, :text=>true

    primary_key [:revision_sistematica_id, :canonico_documento_id, :etapa]

    index [:canonico_documento_id]
    index [:revision_sistematica_id]
    index [:revision_sistematica_id, :canonico_documento_id]
  end



end

