class Archivo < Sequel::Model
  # @return Result
  def self.agregar_en_rs(archivo,rs,basedir, cd=nil)
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
          archivo_ruta="#{sha256[0]}/#{filename}"
          ruta_completa="#{basedir}/#{archivo_ruta}"
          FileUtils.mkdir_p File.dirname(ruta_completa) unless File.exist?(File.dirname(ruta_completa))
          FileUtils.cp archivo[:tempfile],ruta_completa

          archivo_id=Archivo.insert(:archivo_tipo=>filetype,:archivo_nombre=>filename, :archivo_ruta=>archivo_ruta, :sha256=>sha256)
        else
          archivo_id=archivo_o.first[:id]
        end

        archivo_rs_o=Archivo_Rs.where(:archivo_id=>archivo_id,:revision_sistematica_id=>rs[:id])
        if archivo_rs_o.empty?
          Archivo_Rs.insert(:archivo_id=>archivo_id,:revision_sistematica_id=>rs[:id])
        end
        if cd
          archivo_cd_o=Archivo_Cd.where(:archivo_id=>archivo_id, :canonico_documento_id=>cd[:id])
          if archivo_cd_o.empty?
            Archivo_Cd.insert(:archivo_id=>archivo_id, :canonico_documento_id=>cd[:id])
          end
        end
        result.success( I18n::t("archivo.successful_file_added", filename:filename))
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
