class Revision_Sistematica < Sequel::Model
  one_to_many :busquedas
  many_to_one :grupo
  many_to_one :trs_foco
  many_to_one :trs_objetivo
  many_to_one :trs_perspectiva
  many_to_one :trs_cobertura
  many_to_one :trs_organizacion
  many_to_one :trs_destinatario

  TRS=["foco","objetivo","perspectiva","cobertura","organizacion","destinatario"]
  TRS_p=["focos","objetivos","perspectivas","coberturas","organizaciones","destinatarios"]


  ETAPAS=[:busqueda, :primera_revision, :segunda_revision, :analisis, :sintesis]

  ETAPAS_NOMBRE={:busqueda => "Búsqueda", :primera_revision => "Primera revisión (titulo y resumen)", :segunda_revision => "Segunda revisión (lectura rápida)", :analisis => "Análisis", :sintesis => "Síntesis"}

  def palabras_claves_as_array
    palabras_claves.nil? ? nil : palabras_claves.split(";").map {|v| v.strip}


  end
  def grupo_nombre
    grupo.nil? ? "--Sin grupo asignado --" : grupo.name
  end

  def etapa_nombre
    ETAPAS_NOMBRE[self.etapa.to_sym]
  end
  def administrador_nombre
    self[:administrador_revision].nil? ? "--Sin administrador asignado --" : Usuario[self[:administrador_revision]].nombre
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
               (cd_registro_id + cd_referencia_id).uniq
             else
               raise "Tipo no definido"
           end
    Canonico_Documento.where(:id => cd_ids)
  end

  # Entrega dataset con las referencias que existen entre
  # canonicos.
  # Los campos son cd_origen y cd_destino
  def referencias_entre_canonicos
    $db["SELECT r.canonico_documento_id as cd_origen, ref.canonico_documento_id as cd_destino FROM registros r INNER JOIN busquedas_registros br ON r.id=br.registro_id INNER JOIN busquedas b ON br.busqueda_id=b.id  INNER JOIN  referencias_registros rr ON rr.registro_id=r.id INNER JOIN referencias ref ON ref.id=rr.referencia_id   WHERE revision_sistematica_id=? AND ref.canonico_documento_id IS NOT NULL GROUP BY cd_origen, cd_destino", self[:id]]

  end

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
<key id="d5" for="node" attr.name="on_register" attr.type="boolean"/>
<key id="d6" for="node" attr.name="on_reference" attr.type="boolean"/>
<key id="d3" for="node" attr.name="input_n"    attr.type="int"/>
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

</node>"
    }.join("\n")
    edges=ars.rec.map {|v|
      "<edge source='n#{v[:cd_origen]}' target='n#{v[:cd_destino]}' directed='true' />"
    }.join("\n")
    footer="\n</graph>\n</graphml>"
    [head, nodos, edges, footer].join("\n")
  end


end