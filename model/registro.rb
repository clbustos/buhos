require_relative 'canonico_documento'

class Registro < Sequel::Model
  include MetodosReferencia
  include DOIHelpers
  many_to_one :canonico_documento, :class=>Canonico_Documento
  # Obtener una Query Crossref. Se utiliza el APA 6
  def crossref_query
    Crossref_Query.generar_query_desde_texto( ref_apa_6 )
  end
  # Asigna un doi automaticamente desde crossref
  # y verifica que el DOI del canónico calce
  def doi_automatico_crossref
    result=Result.new
    if self.doi.nil? or self.doi==""
      query=crossref_query
      if query[0]["score"]>100
        result.add_result(agregar_doi(query[0]["doi"]))
        result.success("Registro #{self[:id]} tiene DOI #{query[0]["doi"]}")
      else
        result.warning("Registro #{self[:id]} no tiene un referente claro. Debe revisarse a mano")
      end

    elsif canonico_documento.doi.nil?
        result.add_result(agregar_doi(self[:doi]))
    elsif canonico_documento.doi!=self[:doi]
        result.warning("DOI para canonico #{canonico_documento[:doi]}  y referencia #{self[:id]} -> #{self[:doi]} difieren")
    end
    result
  end

  # @param referencias_id ID de referencias que deberían estar acá
  def actualizar_referencias(referencias_id,modo=:sincronia)
    result=Result.new
    cit_ref_yap=$db["SELECT referencia_id FROM referencias_registros WHERE registro_id=?", self[:id]].map {|v| v[:referencia_id]}

    cit_rep_por_ingresar = referencias_id- cit_ref_yap
    cit_rep_por_borrar = cit_ref_yap - referencias_id
    $db.transaction do
      if cit_rep_por_ingresar.length>0
        $db[:referencias_registros].multi_insert(cit_rep_por_ingresar.map {|v| {:referencia_id => v, :registro_id => self[:id]}})
        result.info("Agregadas #{cit_rep_por_ingresar.length} referencias a registro #{self[:id]}")
      end

      if cit_rep_por_borrar.length>0 and modo==:sincronia
        $db[:referencias_registros].where(:registro_id => self[:id], :referencia_id => cit_rep_por_borrar).delete
        result.info("Eliminadas #{cit_rep_por_borrar.length} referencias a registro #{self[:id]}")
      end
    end
    result

  end

  def referencias_automatico_crossref
    result=Result.new
    ri_json=Crossref_Doi.reference_integrator_json(self[:doi])
    if(ri_json and ri_json.references)
      ref_ids=[]
      ri_json.references.each do |reference|
        doi=reference.doi
        texto=reference.to_s
        ref=Referencia.get_by_text_and_doi(texto,doi,true)
        if doi
          cd=Canonico_Documento.where(:doi=>doi_sin_http(doi)).first
          ref.update(:canonico_documento_id=>cd[:id]) if cd and ref.canonico_documento_id.nil?
        end
        ref_ids.push(ref[:id])
      end
      result.add_result(actualizar_referencias(ref_ids,:aditivo))
    end
    result
  end

  # @param doi
  # @return Result
  def agregar_doi(doi)
    status=Result.new
    crossref_doi=Crossref_Doi.procesar_doi(doi)

    unless crossref_doi
      status.error("No puedo procesar DOI #{doi}")
      return status
    end

    #$log.info(co)
    if self[:doi]==doi
      status.info("Ya agregado DOI para registro #{self[:id]}")
    else
      self.update(:doi=>doi_sin_http(doi))
      status.success("Se agrega DOI #{doi} para registro #{self[:id]}")
    end

    # Verificamos si el canónico calza con el original
    can_doc_original=Canonico_Documento[self[:canonico_documento_id]]
    can_doc_doi=Canonico_Documento.where(:doi=>doi_sin_http(doi)).first
    if can_doc_original[:doi]==doi_sin_http(doi)
      status.info("Doi ya incoporado en canónico")
    elsif !can_doc_doi # No hay ningún doc previo con este problema
      can_doc_original.update(:doi=>doi_sin_http(doi))
      status.success("Se agrega a canónico #{can_doc_original[:id]} el DOI #{doi}")
    else  # Ok, tenemos un problema. No lo podemos resolver ahora, sólo podemos avisar en el canónico
      can_doc_original.update(:doi=>doi_sin_http(doi),:duplicated=>can_doc_doi[:id])
      status.warning("Se agregó a canónico #{can_doc_original[:doi]} el DOI, pero existe un duplicado (#{can_doc_doi[:id]}). Revisar")
    end
    status
  end


end
