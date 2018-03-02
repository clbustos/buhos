# Mixin for methods to view and create
# views related to systematic reviews
module SystematicReviewViewsMixin
# Cuenta el número de references hechas a cada reference para la segunda stage
# Se eliminan como destinos aquellos documentos que ya fueron parte de la resolución de la primera stage
  def count_references_rtr_tn
    "sr_#{self[:id]}_references_between_cd_rtr_n"
  end

  def count_references_rtr
    references_bw_canonical
    resolutions_titulo_resumen # Verifico que exista la tabla de resolutions
    view_name = count_references_rtr_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT cd_end , COUNT(DISTINCT(cd_start)) as n_references_rtr  FROM resolutions r INNER JOIN #{references_bw_canonical_tn} rec ON r.canonical_document_id=rec.cd_start LEFT JOIN #{resolutions_titulo_resumen_tn} as r2 ON r2.canonical_document_id=rec.cd_end WHERE r.systematic_review_id=#{self[:id]} and r.stage='screening_title_abstract' and r.resolution='yes' and r2.canonical_document_id IS NULL GROUP BY cd_end")
    end
    $db[view_name.to_sym]

  end


  def resolutions_full_text
    view_name = resolutions_full_text_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='review_full_text'")
    end
    $db[view_name.to_sym]
  end

  def resolutions_full_text_tn
    "sr_#{self[:id]}_resolutions_full_text"
  end

  def resolutions_references
    view_name = resolutions_references_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='screening_references'")
    end
    $db[view_name.to_sym]
  end

  def resolutions_references_tn
    "sr_#{self[:id]}_resolutions_references"
  end

  def resolutions_titulo_resumen
    view_name = resolutions_titulo_resumen_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resolutions  where systematic_review_id=#{self[:id]} and stage='screening_title_abstract'")
    end
    $db[view_name.to_sym]
  end

  def resolutions_titulo_resumen_tn
    "sr_#{self[:id]}_resolutions_sta"
  end

  def count_references_bw_canonical
    view_name = count_references_bw_canonical_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT cd.canonical_document_id as cd_id, COUNT(DISTINCT(r1.cd_end)) as n_total_references_made, COUNT(DISTINCT(r2.cd_start)) as n_total_references_in FROM #{cd_id_table_tn} cd LEFT JOIN #{references_bw_canonical_tn} r1 ON cd.canonical_document_id=r1.cd_start LEFT JOIN #{references_bw_canonical_tn} r2 ON cd.canonical_document_id=r2.cd_end GROUP BY cd.canonical_document_id")
    end
    $db[view_name.to_sym]
  end

  # THis is

  def count_references_bw_canonical_tn
    "sr_#{self[:id]}_references_between_cd_n"
  end


  def references_bw_canonical_tn
    "sr_#{self[:id]}_references_between_cd"

  end

  # Entrega dataset con las references que existen entre
# canonicos.
# Los campos son cd_start y cd_end
  def references_bw_canonical
    view_name = references_bw_canonical_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT r.canonical_document_id as cd_start, ref.canonical_document_id as cd_end FROM records r INNER JOIN records_searches br ON r.id=br.record_id INNER JOIN searches b ON br.search_id=b.id  INNER JOIN  records_references rr ON rr.record_id=r.id INNER JOIN bib_references ref ON ref.id=rr.reference_id   WHERE systematic_review_id='#{self[:id]}' AND ref.canonical_document_id IS NOT NULL AND b.valid=1 GROUP BY cd_start, cd_end")
    end
    $db[view_name.to_sym]
  end


# Entrega todos los id pertinentes para la revision sistematica
  def cd_id_table
    view_name = cd_id_table_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT DISTINCT(r.canonical_document_id) FROM records r INNER JOIN records_searches br ON r.id=br.record_id INNER JOIN searches b ON br.search_id=b.id WHERE b.systematic_review_id=#{self[:id]} AND b.valid=1

      UNION

      SELECT DISTINCT r.canonical_document_id FROM searches b INNER JOIN records_searches br ON b.id=br.search_id INNER JOIN records_references rr ON br.record_id=rr.record_id INNER JOIN bib_references r ON rr.reference_id=r.id  WHERE b.systematic_review_id=#{self[:id]} and r.canonical_document_id IS NOT NULL and b.valid=1 GROUP BY r.canonical_document_id")
    end
    $db[view_name.to_sym]
  end

# Vistas especiales
  def cd_id_table_tn
    "rs_cd_id_#{self[:id]}"
  end
end
