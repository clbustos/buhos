# Mixin for methods to view and create
# views related to systematic reviews
module RevisionSistematicaViewsMixin
# Cuenta el número de referencias hechas a cada referencia para la segunda etapa
# Se eliminan como destinos aquellos documentos que ya fueron parte de la resolución de la primera etapa
  def cuenta_referencias_rtr
    referencias_entre_canonicos
    resoluciones_titulo_resumen # Verifico que exista la tabla de resoluciones
    view_name = cuenta_referencias_rtr_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT cd_destino , COUNT(DISTINCT(cd_origen)) as n_referencias_rtr  FROM resoluciones r INNER JOIN #{referencias_entre_canonicos_tn} rec ON r.canonico_documento_id=rec.cd_origen LEFT JOIN #{resoluciones_titulo_resumen_tn} as r2 ON r2.canonico_documento_id=rec.cd_destino WHERE r.revision_sistematica_id=#{self[:id]} and r.etapa='screening_title_abstract' and r.resolucion='yes' and r2.canonico_documento_id IS NULL GROUP BY cd_destino")
    end
    $db[view_name.to_sym]

  end

  def cuenta_referencias_rtr_tn
    "sr_#{self[:id]}_references_between_cd_rtr_n"
  end

  def resoluciones_texto_completo
    view_name = resoluciones_texto_completo_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resoluciones  where revision_sistematica_id=#{self[:id]} and etapa='review_full_text'")
    end
    $db[view_name.to_sym]
  end

  def resoluciones_texto_completo_tn
    "sr_#{self[:id]}_resolutions_full_text"
  end

  def resoluciones_referencias
    view_name = resoluciones_referencias_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resoluciones  where revision_sistematica_id=#{self[:id]} and etapa='screening_references'")
    end
    $db[view_name.to_sym]
  end

  def resoluciones_referencias_tn
    "sr_#{self[:id]}_resolutions_references"
  end

  def resoluciones_titulo_resumen
    view_name = resoluciones_titulo_resumen_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT * FROM resoluciones  where revision_sistematica_id=#{self[:id]} and etapa='screening_title_abstract'")
    end
    $db[view_name.to_sym]
  end

  def resoluciones_titulo_resumen_tn
    "sr_#{self[:id]}_resolutions_sta"
  end

  def cuenta_referencias_entre_canonicos
    view_name = cuenta_referencias_entre_canonicos_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT cd.canonico_documento_id as cd_id, COUNT(DISTINCT(r1.cd_destino)) as n_total_referencias_hechas, COUNT(DISTINCT(r2.cd_origen)) as n_total_referencias_recibidas FROM #{cd_id_table_tn} cd LEFT JOIN #{referencias_entre_canonicos_tn} r1 ON cd.canonico_documento_id=r1.cd_origen LEFT JOIN #{referencias_entre_canonicos_tn} r2 ON cd.canonico_documento_id=r2.cd_destino GROUP BY cd.canonico_documento_id")
    end
    $db[view_name.to_sym]
  end

  def cuenta_referencias_entre_canonicos_tn
    "sr_#{self[:id]}_references_between_cd_n"
  end

# Entrega dataset con las referencias que existen entre
# canonicos.
# Los campos son cd_origen y cd_destino
  def referencias_entre_canonicos
    view_name = referencias_entre_canonicos_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT r.canonico_documento_id as cd_origen, ref.canonico_documento_id as cd_destino FROM registros r INNER JOIN busquedas_registros br ON r.id=br.registro_id INNER JOIN busquedas b ON br.busqueda_id=b.id  INNER JOIN  referencias_registros rr ON rr.registro_id=r.id INNER JOIN referencias ref ON ref.id=rr.referencia_id   WHERE revision_sistematica_id='#{self[:id]}' AND ref.canonico_documento_id IS NOT NULL AND b.valid=1 GROUP BY cd_origen, cd_destino")
    end
    $db[view_name.to_sym]
  end

  def referencias_entre_canonicos_tn
    "sr_#{self[:id]}_references_between_cd"

  end

# Entrega todos los id pertinentes para la revision sistematica
  def cd_id_table
    view_name = cd_id_table_tn
    if !$db.table_exists?(view_name)
      $db.run("CREATE VIEW #{view_name} AS SELECT DISTINCT(r.canonico_documento_id) FROM registros r INNER JOIN busquedas_registros br ON r.id=br.registro_id INNER JOIN busquedas b ON br.busqueda_id=b.id WHERE b.revision_sistematica_id=#{self[:id]} AND b.valid=1

      UNION

      SELECT DISTINCT r.canonico_documento_id FROM busquedas b INNER JOIN busquedas_registros br ON b.id=br.busqueda_id INNER JOIN referencias_registros rr ON br.registro_id=rr.registro_id INNER JOIN referencias r ON rr.referencia_id=r.id  WHERE b.revision_sistematica_id=#{self[:id]} and r.canonico_documento_id IS NOT NULL and b.valid=1 GROUP BY r.canonico_documento_id")
    end
    $db[view_name.to_sym]
  end

# Vistas especiales
  def cd_id_table_tn
    "rs_cd_id_#{self[:id]}"
  end
end
