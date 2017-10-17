get '/archivos/rs/:revision_sistematica_id/asignar_canonicos_documentos' do |rs_id|
  rs=Revision_Sistematica[rs_id]
  return 404 if rs.nil?
  require 'pdf-reader'
  # Solo buscar en los archivos que no tienen canonico asignado
  pdf_por_revisar=Archivo_Rs.archivos_sin_cd(rs_id).where(:archivo_tipo=>'application/pdf')
  pdf_por_revisar.each do |pdf|
    reader=PDF::Reader.new(pdf.absolute_path(dir_archivos))
      begin
        doi=nil
        info=reader.info
        if(info[:doi])
          doi=info[:doi]
        elsif(info[:Subject])
          doi=encontrar_doi(info[:Subject])
        end
        if doi.nil?
          primera_pagina=reader.pages[0].text
          doi=encontrar_doi(primera_pagina)
        end

        if(doi)
          cd=Canonico_Documento.where(:doi=>doi)
          if cd.count>0
            $db.transaction do
              Archivo_Cd.insert(:archivo_id=>pdf[:id], :canonico_documento_id=>cd.first[:id])
            end
            agregar_mensaje("Agregado archivo #{pdf[:archivo_nombre]} a canónico #{cd[:title]}")
          else
            agregar_mensaje("No puedo encontrar doi: #{doi} en los canonicos",:warning)
          end
        else
          agregar_mensaje("No puedo encontrar doi en el documento #{pdf[:archivo_nombre]}",:warning)
        end

      rescue Exception=>e
        $log.error("Error en archivo:#{pdf[:archivo_nombre]}")
        agregar_mensaje("Error en el archivo #{pdf[:archivo_nombre]}",:error)
        #raise
      end
    end
  redirect back
end

get '/archivo/:id/ver' do |id|
  archivo=Archivo[id]
  return 404 if archivo.nil?

  headers["Content-Disposition"] = "attachment;filename=#{archivo[:archivo_nombre]}"

  content_type archivo[:archivo_tipo]
  send_file(archivo.absolute_path(dir_archivos))
end