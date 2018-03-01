require_relative 'revision_sistematica_views_mixin.rb'
require_relative 'tag'
require_relative 'mensajes'
class Revision_Sistematica < Sequel::Model
  include RevisionSistematicaViewsMixin
  one_to_many :busquedas
  one_to_many :mensajes_rs, :class=>Mensaje_Rs

  one_to_many :t_clases, :class=>T_Clase
  many_to_one :grupo







  def keywords_as_array
    palabras_claves.nil? ? nil : palabras_claves.split(";").map {|v| v.strip}
  end

  def current_stages
    stages=Buhos::Stages::IDS
    stages[0..stages.find_index(self.etapa.to_sym)]
  end
  def group_name
    grupo.nil? ? "--#{::I18n::t(:group_not_assigned)}--" : grupo.name
  end

  def taxonomy_categories_id
    Systematic_Review_SRTC.where(:sr_id=>self[:id]).map(:srtc_id)
  end

  def t_clases_documentos
    @t_clases_documentos||=t_clases_dataset.where(:tipo=>"documento")
  end

  def tags_estadisticas(etapa=nil)
    cd_query=1
    if etapa
      cd_ids=cd_id_by_stage(etapa)
      cd_query=" canonico_documento_id IN (#{cd_ids.join(",")}) "
    end

    $db["SELECT t.*, CASE WHEN tecl.tag_id IS NOT NULL THEN 1 ELSE 0 END  as tag_en_clases FROM (SELECT `tags`.*, COUNT(DISTINCT(canonico_documento_id)) as n_documentos, 1.0*SUM(CASE WHEN decision='yes' THEN 1 ELSE 0 END)/COUNT(*) as p_yes FROM `tags` INNER JOIN `tags_en_cds` tec ON (tec.`tag_id` = `tags`.`id`)
WHERE tec.revision_sistematica_id=?
AND  #{cd_query} GROUP BY tags.id ORDER BY n_documentos DESC ,p_yes DESC,tags.texto ASC) as t LEFT JOIN tags_en_clases tecl ON t.id=tecl.tag_id GROUP BY t.id
 ", self.id]


  end


  def group_users
    grupo.nil? ? nil : grupo.usuarios
  end
  def etapa_nombre
    Buhos::Stages.get_stage_name(self.etapa.to_sym)
  end
  def administrador_nombre
    self[:administrador_revision].nil? ? "-- #{I18n::t(:administrator_not_assigned)} --" : Usuario[self[:administrador_revision]].nombre
  end
  def get_nombres_trs
    (0...TRS.length).inject({}) {|ac,v|

      res=$db["trs_#{TRS_p[v]}".to_sym].where(:id=>self["trs_#{TRS[v]}_id".to_sym]).get(:name)
      ac[TRS[v]]=res
      ac
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
    Registro.join(:busquedas_registros, :registro_id => :id).join(:busquedas, :id => :busqueda_id).join(Revision_Sistematica.where(:id => self[:id]), :id => :revision_sistematica_id).select_all(:canonicos_documentos).where(:valid=>true).group(:canonico_documento_id).select_map(:canonico_documento_id)
  end

  def cd_referencia_id
    $db["SELECT canonico_documento_id FROM busquedas b INNER JOIN busquedas_registros br ON b.id=br.busqueda_id INNER JOIN referencias_registros rr ON br.registro_id=rr.registro_id INNER JOIN referencias r ON rr.referencia_id=r.id  WHERE b.revision_sistematica_id=? and r.canonico_documento_id IS NOT NULL AND b.valid=1 GROUP BY r.canonico_documento_id", self[:id]].select_map(:canonico_documento_id)
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
               raise (I18n::t(:Not_defined_for_this_stage))
           end
    if tipo==:todos
      Canonico_Documento.join(cd_id_table, canonico_documento_id: :id   )
    else
      Canonico_Documento.where(:id => cd_ids)

    end
  end
  # Nombre de la tabla para referencias entre canonicos



  def cd_id_resoluciones(etapa)
    Resolucion.where(:revision_sistematica_id=>self[:id], :etapa=>etapa.to_s,:canonico_documento_id=>cd_todos_id,:resolucion=>'yes').map(:canonico_documento_id)
  end



  # Entrega la lista de canónicos documentos apropiados para cada etapa
  def cd_id_by_stage(etapa)
    case etapa.to_s
      when 'search'
        cd_registro_id # TODO: Check this
      when 'screening_title_abstract'
        cd_registro_id
      when 'screening_references'
        cuenta_referencias_rtr.where( Sequel.lit("n_referencias_rtr >= #{self[:n_min_rr_rtr]}") ).map(:cd_destino)
        # Solo dejamos aquellos que tengan más de una referencias
      when 'review_full_text'
        rtr=resoluciones_titulo_resumen.where(:resolucion=>'yes').select_map(:canonico_documento_id)
        rr=resoluciones_referencias.where(:resolucion=>'yes').select_map(:canonico_documento_id)
        (rtr+rr).uniq
      when 'report'
        resoluciones_texto_completo.where(:resolucion=>'yes').select_map(:canonico_documento_id)
      else

        raise 'no definido'
    end
  end
  def fields
    Rs_Campo.where(:revision_sistematica_id=>self[:id]).order(:orden)
  end
  def analisis_cd_tn
    "analisis_rs_#{self[:id]}"
  end
  # Entrega la tabla de texto completo
  def analisis_cd
    table_name=analisis_cd_tn
    if !$db.table_exists?(table_name)
      Rs_Campo.actualizar_tabla(self)
    end
    $db[table_name.to_sym]
  end

  def analisis_cd_user_row(cd,user)
    out=analisis_cd[:canonico_documento_id=>cd[:id], :usuario_id=>user[:id]]
    if !out
      out_id=analisis_cd.insert(:canonico_documento_id=>cd[:id], :usuario_id=>user[:id])
      out=analisis_cd[:id=>out_id]
    end
    out
  end


  def taxonomy_categories_hash
    $db["SELECT sr.name as sr_name, src.name as cat_name FROM sr_taxonomies sr INNER JOIN sr_taxonomy_categories src ON sr.id=src.srt_id INNER JOIN systematic_review_srtcs  srsrtcs ON srsrtcs.srtc_id=src.id WHERE srsrtcs.sr_id=? ORDER BY sr_name, cat_name",self[:id]].to_hash_groups(:sr_name)
  end
end