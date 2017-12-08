require_relative 'tag'
require_relative 'mensajes'
class Revision_Sistematica < Sequel::Model
  one_to_many :busquedas
  one_to_many :mensajes_rs, :class=>Mensaje_Rs

  one_to_many :t_clases, :class=>T_Clase
  many_to_one :grupo
  many_to_one :trs_foco
  many_to_one :trs_objetivo
  many_to_one :trs_perspectiva
  many_to_one :trs_cobertura
  many_to_one :trs_organizacion
  many_to_one :trs_destinatario


  TRS=["foco","objetivo","perspectiva","cobertura","organizacion","destinatario"]
  TRS_p=["focos","objetivos","perspectivas","coberturas","organizaciones","destinatarios"]


  ETAPAS=[:busqueda,
          :revision_titulo_resumen,
          :revision_referencias,
          :revision_texto_completo,
          :analisis,
          :sintesis]

  ETAPAS_NOMBRE={:busqueda => "stage.search",
                 :revision_titulo_resumen => "stage.review_title_and_abstract",
                 :revision_referencias => "stage.review_references",
                 :revision_texto_completo=> "stage.review_full_text",
                 :analisis => "stage.analysis",
                 :sintesis => "stage.synthesis"}

  def palabras_claves_as_array
    palabras_claves.nil? ? nil : palabras_claves.split(";").map {|v| v.strip}
  end
  def etapas_avanzadas
    ETAPAS[0..ETAPAS.find_index(self.etapa.to_sym)]
  end
  def grupo_nombre
    grupo.nil? ? "--#{t(:group_not_assigned)}--" : grupo.name
  end


  def t_clases_documentos
    @t_clases_documentos||=t_clases_dataset.where(:tipo=>"documento")
  end

  def tags_estadisticas(etapa=nil)
    cd_query=1
    if etapa
      cd_ids=cd_id_por_etapa(etapa)
      cd_query=" canonico_documento_id IN (#{cd_ids.join(",")}) "
    end
    $db["SELECT `tags`.*, COUNT(DISTINCT(canonico_documento_id)) as n_documentos, 0+SUM(IF(decision='yes',1,0))/COUNT(*) as p_yes, IF(tc_id IS NOT NULL,1,0) as con_clase FROM `tags` INNER JOIN `tags_en_cds` tec ON (tec.`tag_id` = `tags`.`id`) LEFT JOIN `tags_en_clases` tcla ON tcla.`tag_id` = tec.`tag_id` WHERE tec.revision_sistematica_id=? AND #{cd_query} GROUP BY tags.id ORDER BY n_documentos DESC ,p_yes DESC,tags.texto ASC", self.id]

  end

  def self.get_nombre_etapa(etapa)
    ETAPAS_NOMBRE[etapa.to_sym]
  end
  def grupo_usuarios
    grupo.nil? ? nil : grupo.usuarios
  end
  def etapa_nombre
    ETAPAS_NOMBRE[self.etapa.to_sym]
  end
  def administrador_nombre
    self[:administrador_revision].nil? ? "-- #{t(:administrator_not_assigned)} --" : Usuario[self[:administrador_revision]].nombre
  end
  def get_nombres_trs
    (0...TRS.length).inject({}) {|ac,v|

      res=$db["trs_#{TRS_p[v]}".to_sym].where(:id=>self["trs_#{TRS[v]}_id".to_sym]).get(:name)
      ac[TRS[v]]=res;
      ac;
    }
  end
  def self.get_revisiones_por_usuario(us_id)
    ids=$db["SELECT r.id FROM revisiones_sistematicas r INNER JOIN grupos_usuarios gu on r.grupo_id=gu.grupo_id WHERE gu.usuario_id='#{us_id}'"].map{|v|v[:id]}
    Revision_Sistematica.where(:id=>ids)
  end

  def doi_repetidos
    canonicos_documentos.exclude(doi: nil).group_and_count(:doi).having {count.function.* > 1}.all.map {|v| v[:doi]}
  end

  def cd_registro_id
    Registro.join(:busquedas_registros, :registro_id => :id).join(:busquedas, :id => :busqueda_id).join(Revision_Sistematica.where(:id => self[:id]), :id => :revision_sistematica_id).select_all(:canonicos_documentos).group(:canonico_documento_id).select_map(:canonico_documento_id)
  end

  def cd_referencia_id
    $db["SELECT canonico_documento_id FROM busquedas b INNER JOIN busquedas_registros br ON b.id=br.busqueda_id INNER JOIN referencias_registros rr ON br.registro_id=rr.registro_id INNER JOIN referencias r ON rr.referencia_id=r.id  WHERE b.revision_sistematica_id=? and r.canonico_documento_id IS NOT NULL GROUP BY r.canonico_documento_id", self[:id]].select_map(:canonico_documento_id)
  end





  def cd_todos_id
    (cd_registro_id + cd_referencia_id).uniq
  end
  def cd_hash
    @cd_hash||=Canonico_Documento.where(:id=>cd_todos_id).as_hash
  end

  # Presenta los documentos canonicos
  # para la revision. Une los por
  # registro y referencia

  def canonicos_documentos(tipo=:todos)
    cd_ids=case tipo
             when :registro
               cd_registro_id
             when :referencia
               cd_referencia_id
             when :todos
                cd_todos_id
             else
               raise "Tipo no definido"
           end
    if tipo==:todos
      Canonico_Documento.join(cd_id_table, canonico_documento_id: :id   )
    else
      Canonico_Documento.where(:id => cd_ids)

    end
  end
  # Nombre de la tabla para referencias entre canonicos


  def generar_graphml
    ars=AnalisisRevisionSistematica.new(self)


    cd_hash=canonicos_documentos.order(:year).as_hash

    head=<<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">

<key id="d0" for="node" attr.name="doi"        attr.type="string"/>
<key id="d1" for="node" attr.name="title"      attr.type="string"/>
<key id="d2" for="node" attr.name="year"       attr.type="int"/>
<key id="d3" for="node" attr.name="input_n"    attr.type="int"/>
<key id="d5" for="node" attr.name="on_register" attr.type="boolean"/>
<key id="d6" for="node" attr.name="on_reference" attr.type="boolean"/>
<key id="d7" for="node" attr.name="on_title_abstract" attr.type="boolean"/>
<key id="output_n" for="node" attr.name="output_n"   attr.type="int"/>

<graph id="G" edgedefault="directed">

HEREDOC
    nodos=cd_hash.map {|v|
      str="<node id='n#{v[0]}'>"
      if v[1].doi
        str+="<data key='d0'><![CDATA[#{CGI.escapeHTML(v[1].doi)}]]></data>"
      else
        str+="<data key='d0'></data>"
      end
      str+="<data key='d1'><![CDATA[#{CGI.escapeHTML(v[1].title)}]]></data>
<data key='d2'>#{v[1].year.to_i}</data>
<data key='d3'>#{ars.cd_count_entrada(v[0]).to_i}</data>
<data key='output_n'>#{ars.cd_count_salida(v[0]).to_i}</data>
<data key='d5'>#{ars.cd_en_registro?(v[0]) ? "true" : "false"}</data>
<data key='d6'>#{ars.cd_en_referencia?(v[0]) ? "true" : "false"}</data>
<data key='d7'>#{ars.cd_en_resolucion_etapa?(v[0],"revision_titulo_resumen") ? "true" : "false"}</data>
</node>"
    }.join("\n")
    edges=ars.rec.map {|v|
      "<edge source='n#{v[:cd_origen]}' target='n#{v[:cd_destino]}' directed='true' />"
    }.join("\n")
    footer="\n</graph>\n</graphml>"
    [head, nodos, edges, footer].join("\n")
  end
  def cd_id_resoluciones(etapa)
    Resolucion.where(:revision_sistematica_id=>self[:id], :etapa=>etapa.to_s,:canonico_documento_id=>cd_todos_id,:resolucion=>'yes').map(:canonico_documento_id)
  end

# Vistas especiales

  def cd_id_table_tn
    "rs_cd_id_#{self[:id]}"
  end
  # Entrega todos los id pertinentes para la revision sistematica
  def cd_id_table
    view_name=cd_id_table_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT DISTINCT(r.canonico_documento_id) FROM registros r INNER JOIN busquedas_registros br ON r.id=br.registro_id INNER JOIN busquedas b ON br.busqueda_id=b.id WHERE b.revision_sistematica_id=#{self[:id]}

      UNION DISTINCT

      SELECT DISTINCT r.canonico_documento_id FROM busquedas b INNER JOIN busquedas_registros br ON b.id=br.busqueda_id INNER JOIN referencias_registros rr ON br.registro_id=rr.registro_id INNER JOIN referencias r ON rr.referencia_id=r.id  WHERE b.revision_sistematica_id=#{self[:id]} and r.canonico_documento_id IS NOT NULL GROUP BY r.canonico_documento_id")
    end
    $db[view_name.to_sym]
  end


  def referencias_entre_canonicos_tn
    "referencias_entre_cn_#{self[:id]}"

  end

  # Entrega dataset con las referencias que existen entre
  # canonicos.
  # Los campos son cd_origen y cd_destino

  def referencias_entre_canonicos
    view_name=referencias_entre_canonicos_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT r.canonico_documento_id as cd_origen, ref.canonico_documento_id as cd_destino FROM registros r INNER JOIN busquedas_registros br ON r.id=br.registro_id INNER JOIN busquedas b ON br.busqueda_id=b.id  INNER JOIN  referencias_registros rr ON rr.registro_id=r.id INNER JOIN referencias ref ON ref.id=rr.referencia_id   WHERE revision_sistematica_id='#{self[:id]}' AND ref.canonico_documento_id IS NOT NULL GROUP BY cd_origen, cd_destino")
    end
    $db[view_name.to_sym]
  end

  def cuenta_referencias_entre_canonicos_tn
    "referencias_entre_cn_n_#{self[:id]}"
  end


  def cuenta_referencias_entre_canonicos
    view_name=cuenta_referencias_entre_canonicos_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT cd.canonico_documento_id as cd_id, COUNT(DISTINCT(r1.cd_destino)) as n_total_referencias_hechas, COUNT(DISTINCT(r2.cd_origen)) as n_total_referencias_recibidas FROM #{cd_id_table_tn} cd LEFT JOIN #{referencias_entre_canonicos_tn} r1 ON cd.canonico_documento_id=r1.cd_origen LEFT JOIN #{referencias_entre_canonicos_tn} r2 ON cd.canonico_documento_id=r2.cd_destino GROUP BY cd.canonico_documento_id")
    end
    $db[view_name.to_sym]
  end

  def resoluciones_titulo_resumen_tn
    "resoluciones_rs_#{self[:id]}_rtr"
  end
  def resoluciones_titulo_resumen
    view_name=resoluciones_titulo_resumen_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT * FROM resoluciones  where revision_sistematica_id=#{self[:id]} and etapa='revision_titulo_resumen'")
    end
    $db[view_name.to_sym]
  end

  def resoluciones_referencias_tn
    "resoluciones_rs_#{self[:id]}_referencias"
  end
  def resoluciones_referencias
    view_name=resoluciones_referencias_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT * FROM resoluciones  where revision_sistematica_id=#{self[:id]} and etapa='revision_referencias'")
    end
    $db[view_name.to_sym]
  end




  def cuenta_referencias_rtr_tn
    "referencias_entre_cn_rtr_n_#{self[:id]}"
  end
  # Cuenta el número de referencias hechas a cada referencia para la segunda etapa
  # Se eliminan como destinos aquellos documentos que ya fueron parte de la resolución de la primera etapa
  def cuenta_referencias_rtr
    resoluciones_titulo_resumen # Verifico que exista la tabla de resoluciones
    view_name=cuenta_referencias_rtr_tn
    if $db["SHOW FULL TABLES  LIKE '%#{view_name}%'"].empty?
      $db.run("CREATE OR REPLACE VIEW #{view_name} AS SELECT cd_destino , COUNT(DISTINCT(cd_origen)) as n_referencias_rtr  FROM resoluciones r INNER JOIN #{referencias_entre_canonicos_tn} rec ON r.canonico_documento_id=rec.cd_origen LEFT JOIN #{resoluciones_titulo_resumen_tn} as r2 ON r2.canonico_documento_id=rec.cd_destino WHERE r.revision_sistematica_id=#{self[:id]} and r.etapa='revision_titulo_resumen' and r.resolucion='yes' and r2.canonico_documento_id IS NULL GROUP BY cd_destino")
    end
    $db[view_name.to_sym]

  end
  # Entrega la lista de canónicos documentos apropiados para cada etapa
  def cd_id_por_etapa(etapa)
    case etapa.to_s
      when 'revision_titulo_resumen'
        cd_registro_id
      when 'revision_referencias'
        cuenta_referencias_rtr.where( Sequel.lit("n_referencias_rtr >= #{self[:n_min_rr_rtr]}") ).map(:cd_destino)
        # Solo dejamos aquellos que tengan más de una referencias
      when 'revision_texto_completo'
        rtr=resoluciones_titulo_resumen.where(:resolucion=>'yes').select_map(:canonico_documento_id)
        rr=resoluciones_referencias.where(:resolucion=>'yes').select_map(:canonico_documento_id)
        (rtr+rr).uniq
      else
        raise 'no definido'
    end
  end
  def campos
    Rs_Campo.where(:revision_sistematica_id=>self[:id]).order(:orden)
  end
  def analisis_cd_tn
    "analisis_rs_#{self[:id]}"
  end
  # Entrega la tabla de texto completo
  def analisis_cd
    table_name=analisis_cd_tn
    if $db["SHOW FULL TABLES  LIKE '%#{table}%'"].empty?
      Rs_Campo.actualizar_tabla(self)
    end
    $db[view_name.to_sym]
  end
end