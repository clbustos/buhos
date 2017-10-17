class Archivo < Sequel::Model
  # @return Result
  def self.agregar_en_rs(archivo,rs,basedir)
    result=Result.new
    $db.transaction do
      filename=archivo[:filename].gsub(/[^A-Za-z0-9\.-_]/,"")
      filetype=archivo[:type]
      if filetype=="application/zip"
      else
        sha256=Digest::SHA256.file(archivo[:tempfile]).hexdigest
        #fp=File.open(archivo[:tempfile],"rb")
        archivo_o=Archivo.where(:sha256=>sha256)
        if archivo_o.empty?
          archivo_ruta="rs_#{@revision.id}/#{filename}"
          ruta_completa="#{basedir}/#{archivo_ruta}"
          FileUtils.mkdir_p File.dirname(ruta_completa) unless File.exist?(File.dirname(ruta_completa))
          FileUtils.cp archivo[:tempfile],ruta_completa

          archivo_id=Archivo.insert(:archivo_tipo=>filetype,:archivo_nombre=>filename, :archivo_ruta=>archivo_ruta, :sha256=>sha256)
        else
          archivo_id=archivo_o[:id]
        end

        archivo_rs_o=Archivo_Rs.where(:archivo_id=>archivo_id,:revision_sistematica_id=>rs[:id])
        if archivo_rs_o.empty?
          Archivo_Rs.insert(:archivo_id=>archivo_id,:revision_sistematica_id=>rs[:id])
        end
        result.success("Agregado archivo #{filename} con exito")
      end
    end
    result
  end

  def absolute_path(basedir)
    "#{basedir}/#{self[:archivo_ruta]}"
  end
end
class Archivo_Cd < Sequel::Model

end

class Archivo_Rs < Sequel::Model
  def self.archivos_sin_cd(rs_id)
    Archivo.join(:archivos_rs, :archivo_id=>:id).left_join(:archivos_cds, :archivo_id=>:archivo_id).where(:revision_sistematica_id=>rs_id,:canonico_documento_id=>nil).select_all(:archivos)
  end
end
