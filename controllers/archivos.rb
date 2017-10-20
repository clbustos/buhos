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

get '/archivo/:id/descargar' do |id|
  archivo=Archivo[id]
  return 404 if archivo.nil?

  headers["Content-Disposition"] = "attachment;filename=#{archivo[:archivo_nombre]}"

  content_type archivo[:archivo_tipo]
  send_file(archivo.absolute_path(dir_archivos))
end

get '/archivo/:id/pagina/:pagina/:formato' do |id,pagina,formato|
  archivo=Archivo[id]
  pagina=pagina.to_i
  return 404 if archivo.nil?
  filepath=archivo.absolute_path(dir_archivos)
  if archivo[:archivo_tipo]=="application/pdf"

    if formato=='text'
      require 'pdf-reader'
      reader=PDF::Reader.new(filepath)
      archivo.update(:paginas=>reader.pages.length) if archivo[:paginas].nil?
      return "No existe pagina" if reader.pages.length<pagina
      reader.pages[pagina-1].text
    elsif formato=='image'
      require 'grim'
      pdf   = Grim.reap(filepath)
      return "No existe pagina" if pdf.count<pagina or pagina<1
      archivo.update(:paginas=>pdf.count) if archivo[:paginas].nil?
      filepath_image="#{dir_archivos}/pdf_imagenes/#{archivo[:sha256]}_#{pagina}.png"
      $log.info(File.dirname(filepath_image))
      FileUtils.mkdir_p File.dirname(filepath_image) unless File.exist? File.dirname(filepath_image)
      unless File.exist? filepath_image
        pdf[pagina-1].save(filepath_image,{
            :density=>300,
            :alpha=>"Set"
        })
      end
      headers["Content-Disposition"] = "inline;filename=#{File.basename(filepath_image)}"
      content_type "image/png"
      send_file(filepath_image)
    else
      raise "No existe el formato"
    end
  else
    return 500
  end
#  headers["Content-Disposition"] = "inline;filename=#{archivo[:archivo_nombre]}"

#  content_type archivo[:archivo_tipo]
#  send_file(archivo.absolute_path(dir_archivos))
end


get '/archivo/:id/ver' do |id|
  archivo=Archivo[id]
  return 404 if archivo.nil?

  headers["Content-Disposition"] = "inline;filename=#{archivo[:archivo_nombre]}"

  content_type archivo[:archivo_tipo]
  send_file(archivo.absolute_path(dir_archivos))
end




post '/archivo/asignar_canonico' do
  archivo=Archivo[params['archivo_id']]
  acd=Archivo_Cd.where(:archivo_id=>archivo.id)
  return 404 if archivo.nil?

  if params['cd_id']==""
    acd.delete
    return "--Sin canonico--"
  else
    cd=Canonico_Documento[params['cd_id']]
    return 404 if !cd
    if acd.empty?
      Archivo_Cd.insert(:archivo_id=>archivo.id,:canonico_documento_id=>cd.id,:no_considerar=>false)
    else
      Archivo_Cd.where(:archivo_id=>archivo.id).update(:canonico_documento_id=>cd.id)
    end
    return "<a href='/canonico_documento/#{cd[:id]}'>#{cd[:title][0..50]}</a>"
  end

end

post '/archivo/ocultar_cd' do
  archivo=Archivo[params['archivo_id']]
  cd=Canonico_Documento[params['cd_id']]
  return 404 if archivo.nil? or cd.nil?

  Archivo_Cd.where(:archivo_id=>archivo.id, :canonico_documento_id=>cd.id).update(:no_considerar=>true)
  return 200
end

post '/archivo/desasignar_cd' do
  archivo=Archivo[params['archivo_id']]
  cd=Canonico_Documento[params['cd_id']]
  return 404 if archivo.nil? or cd.nil?

  Archivo_Cd.where(:archivo_id=>archivo.id, :canonico_documento_id=>cd.id).delete
  return 200
end