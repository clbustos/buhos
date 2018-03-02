require_relative 'revision_sistematica_views_mixin.rb'
require_relative 'tag'
require_relative 'mensajes'
class SystematicReview < Sequel::Model
  include SystematicReviewViewsMixin
  one_to_many :searches
  one_to_many :message_srs, :class=>MessageSr

  one_to_many :t_classes, :class=>T_Class
  many_to_one :group







  def keywords_as_array
    keywords.nil? ? nil : keywords.split(";").map {|v| v.strip}
  end

  def current_stages
    stages=Buhos::Stages::IDS
    stages[0..stages.find_index(self.stage.to_sym)]
  end
  def group_name
    group.nil? ? "--#{::I18n::t(:group_not_assigned)}--" : group.name
  end

  def taxonomy_categories_id
    Systematic_Review_SRTC.where(:sr_id=>self[:id]).map(:srtc_id)
  end

  def t_clases_documentos
    @t_clases_documentos||=t_classes_dataset.where(:type=>"document")
  end

  def tags_estadisticas(stage=nil)
    cd_query=1
    if stage
      cd_ids=cd_id_by_stage(stage)
      cd_query=" canonical_document_id IN (#{cd_ids.join(",")}) "
    end

    $db["SELECT t.*, CASE WHEN tecl.tag_id IS NOT NULL THEN 1 ELSE 0 END  as tag_en_clases FROM (SELECT `tags`.*, COUNT(DISTINCT(canonical_document_id)) as n_documents, 1.0*SUM(CASE WHEN decision='yes' THEN 1 ELSE 0 END)/COUNT(*) as p_yes FROM `tags` INNER JOIN `tag_in_cds` tec ON (tec.`tag_id` = `tags`.`id`)
WHERE tec.systematic_review_id=?
AND  #{cd_query} GROUP BY tags.id ORDER BY n_documents DESC ,p_yes DESC,tags.text ASC) as t LEFT JOIN tag_in_classes tecl ON t.id=tecl.tag_id GROUP BY t.id
 ", self.id]


  end


  def group_users
    group.nil? ? nil : group.users
  end
  def stage_name
    Buhos::Stages.get_stage_name(self.stage.to_sym)
  end
  def administrador_name
    self[:sr_administrator].nil? ? "-- #{I18n::t(:administrator_not_assigned)} --" : User[self[:sr_administrator]].name
  end
  def get_names_trs
    (0...TRS.length).inject({}) {|ac,v|

      res=$db["trs_#{TRS_p[v]}".to_sym].where(:id=>self["trs_#{TRS[v]}_id".to_sym]).get(:name)
      ac[TRS[v]]=res
      ac
    }
  end
  def self.get_revisiones_por_usuario(us_id)
    ids=$db["SELECT r.id FROM systematic_reviews r INNER JOIN groups_users gu on r.group_id=gu.group_id WHERE gu.user_id='#{us_id}'"].map{|v|v[:id]}
    SystematicReview.where(:id=>ids)
  end

  def doi_repetidos
    canonical_documents.exclude(doi: nil).group_and_count(:doi).having {count.function.* > 1}.all.map {|v| v[:doi]}
  end

  def cd_record_id
    Record.join(:records_searches, :record_id => :id).join(:searches, :id => :search_id).join(SystematicReview.where(:id => self[:id]), :id => :systematic_review_id).select_all(:canonical_documents).where(:valid=>true).group(:canonical_document_id).select_map(:canonical_document_id)
  end

  def cd_reference_id
    $db["SELECT canonical_document_id FROM searches b INNER JOIN records_searches br ON b.id=br.search_id INNER JOIN records_references rr ON br.record_id=rr.record_id INNER JOIN bib_references r ON rr.reference_id=r.id  WHERE b.systematic_review_id=? and r.canonical_document_id IS NOT NULL AND b.valid=1 GROUP BY r.canonical_document_id", self[:id]].select_map(:canonical_document_id)
  end





  def cd_todos_id
    (cd_record_id + cd_reference_id).uniq
  end
  def cd_hash
    @cd_hash||=CanonicalDocument.where(:id=>cd_todos_id).as_hash
  end

  # Presenta los documentos canonicos
  # para la revision. Une los por
  # registro y reference

  def canonical_documents(type=:todos)
    cd_ids=case type
             when :registro
               cd_record_id
             when :reference
               cd_reference_id
             when :todos
                cd_todos_id
             else
               raise (I18n::t(:Not_defined_for_this_stage))
           end
    if type==:todos
      CanonicalDocument.join(cd_id_table, canonical_document_id: :id   )
    else
      CanonicalDocument.where(:id => cd_ids)

    end
  end
  # Nombre de la tabla para references entre canonicos



  def cd_id_resolutions(stage)
    Resolution.where(:systematic_review_id=>self[:id], :stage=>stage.to_s,:canonical_document_id=>cd_todos_id,:resolution=>'yes').map(:canonical_document_id)
  end



  # Entrega la lista de canónicos documentos apropiados para cada stage
  def cd_id_by_stage(stage)
    case stage.to_s
      when 'search'
        cd_record_id # TODO: Check this
      when 'screening_title_abstract'
        cd_record_id
      when 'screening_references'
        count_references_rtr.where( Sequel.lit("n_references_rtr >= #{self[:n_min_rr_rtr]}") ).map(:cd_end)
        # Solo dejamos aquellos que tengan más de una references
      when 'review_full_text'
        rtr=resolutions_titulo_resumen.where(:resolution=>'yes').select_map(:canonical_document_id)
        rr=resolutions_references.where(:resolution=>'yes').select_map(:canonical_document_id)
        (rtr+rr).uniq
      when 'report'
        resolutions_full_text.where(:resolution=>'yes').select_map(:canonical_document_id)
      else

        raise 'no definido'
    end
  end
  def fields
    SrField.where(:systematic_review_id=>self[:id]).order(:order)
  end
  def analysis_cd_tn
    "analysis_sr_#{self[:id]}"
  end
  # Entrega la tabla de text completo
  def analysis_cd
    table_name=analysis_cd_tn
    if !$db.table_exists?(table_name)
      SrField.actualizar_tabla(self)
    end
    $db[table_name.to_sym]
  end

  def analysis_cd_user_row(cd,user)
    out=analysis_cd[:canonical_document_id=>cd[:id], :user_id=>user[:id]]
    if !out
      out_id=analysis_cd.insert(:canonical_document_id=>cd[:id], :user_id=>user[:id])
      out=analysis_cd[:id=>out_id]
    end
    out
  end


  def taxonomy_categories_hash
    $db["SELECT sr.name as sr_name, src.name as cat_name FROM sr_taxonomies sr INNER JOIN sr_taxonomy_categories src ON sr.id=src.srt_id INNER JOIN systematic_review_srtcs  srsrtcs ON srsrtcs.srtc_id=src.id WHERE srsrtcs.sr_id=? ORDER BY sr_name, cat_name",self[:id]].to_hash_groups(:sr_name)
  end
end