get '/busqueda/:id/editar' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  haml %s{busquedas/busqueda_edicion}
end

get '/busqueda/:id/registros' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  @registros=@busqueda.registros_dataset.order(:author)

  haml %s{busquedas/busqueda_registros}
end


get '/busqueda/:id/referencias' do |id|
  @busqueda=Busqueda[id]
  @revision=@busqueda.revision_sistematica
  @referencias=@busqueda.referencias
  @referencias_con_canonico=@busqueda.referencias.where(Sequel.lit("canonico_documento_id IS NOT NULL"))
  @n_referencias = params['n_referencias'].nil? ? 20 : params['n_referencias']

  @rmc_canonico     = @busqueda.referencias_con_canonico_n(@n_referencias)

  @rmc_sin_canonico = @busqueda.referencias_sin_canonico_n(@n_referencias)

  @rmc_sin_canonico_con_doi = @busqueda.referencias_sin_canonico_con_doi_n(@n_referencias)

  ##$log.info(@rmc_canonico)

  haml %s{busquedas/busqueda_referencias}
end


get '/busqueda/:id/registros/completar_dois' do |id|
  @busqueda=Busqueda[id]
  @registros=@busqueda.registros_dataset
  result=Result.new()
  correcto=true
  @registros.each do |registro|
    $db.transaction() do
      begin
        result.add_result(registro.doi_automatico_crossref)
        if registro.doi
          #$log.info("Agregando referencias registro #{registro.ref_apa_6}")
          result.add_result(registro.referencias_automatico_crossref)
        end
      rescue BadCrossrefResponseError=>e

        result.error("Problema en registro #{registro[:id]}: #{e.message}. Se interrumpe sincronizacion")
        raise Sequel::Rollback
      end
      $db.after_rollback {
        #result.error("Problema en registro #{registro[:id]}. Se interrumpe sincronizacion")
        correcto=false
      }
    end
    break unless correcto
  end
  agregar_resultado(result)
  redirect back
end


# Busca en el texto algun indicador de DOI
get '/busqueda/:id/referencias/buscar_dois' do |id|
  exitos=0
  @busqueda=Busqueda[id]
  @referencias=@busqueda.referencias.where(:doi=>nil)
  $db.transaction do
    @referencias.each do |referencia|
      if referencia.texto =~/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/
        exitos+=1
        doi=$1
        ##$log.info(doi)
        update_fields={:doi=>doi}
        cd=Canonico_Documento[:doi => doi]
        update_fields[:canonico_documento_id]=cd[:id] if cd
        referencia.update(update_fields)
      end
    end
  end
  agregar_mensaje("Actualizadas #{exitos} referencias con DOI en texto")
  redirect back
end

get '/busqueda/:id/referencias/generar_canonicos_doi/:n' do |id, n|
  busqueda=Busqueda[id]
  col_dois=busqueda.referencias_sin_canonico_con_doi_n(n)
  result=Result.new
  col_dois.each do |col_doi|
    Referencia.where(:doi => col_doi[:doi]).each do |ref|
      result.add_result(ref.agregar_doi(col_doi[:doi]))
    end
  end
  agregar_resultado(result)
  redirect back
end

