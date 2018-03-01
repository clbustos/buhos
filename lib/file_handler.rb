module FileHandler
  # Maneja el javascript para ver archivos de forma modal

    class ModalFiles
      def initialize

      end
      def javascript_header
        "<script src='/js/file_handler.js'></script>"
      end

      def html_modal
        <<HEREDOC
<div aria-labelledby='myModalLabel' class='modal fade' id='modalArchivos' role='dialog' tabindex='-1'>
  <div class='modal-dialog modal-lg' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
        <button aria-label='Cerrar' class='close' data-dismiss='modal' type='button'>
          <span aria-hidden='true'>×</span>
        </button>
        <h4 class='modal-title' id='myModalLabel'>#{I18n.t(:File)}</h4>
      </div>
      <div class='modal-body'>
        
      </div>
    </div>
  </div>
</div>
HEREDOC
      end





      def cargador_archivo(rs_id,cd_id)
        "<form method='post' action='/review/files/add' enctype='multipart/form-data'>
  <input type='hidden' name='revision_sistematica_id' value='#{rs_id}' />
  <input type='hidden' name='canonico_documento_id' value='#{cd_id}' />
  <div class='form-group'>
    <input type='file' name='archivos[]'/>
    <input type='submit' class='btn btn-primary btn-sm' value='#{I18n.t(:Send)}'/>
</div>
</form>"
      end

      def botones(archivo, cd_id=nil, rs_id=nil, eliminar=nil)
        boton_canonico=""
        boton_rs=""
        boton_eliminar=""
        if eliminar
          boton_eliminar="<button class='btn btn-danger archivo_eliminar' role='button' data-aid='#{archivo[:id]}'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t("file_handler.delete_file")}</span>
        </button>"
        end
        if rs_id
          boton_rs="
          <button class='btn btn-warning archivo_desasignar_rs' data-aid='#{archivo[:id]}' data-rsid='#{rs_id}' role='button'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t("file_handler.unassign_systematic_review")}</span>
        </button>
        "
        end
        if cd_id
          acd=Archivo_Cd[:archivo_id=>archivo[:id], :canonico_documento_id=>cd_id]
          if acd
            boton_canonico="
          <button class='btn btn-warning archivo_desasignar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t("file_handler.unassign_canonical_document")}</span>
        </button>"
            if acd[:no_considerar]
        boton_canonico+= "
        <button class='btn btn-default archivo_mostrar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-open'>#{I18n.t("file_handler.show_canonical_document")}</span>
        </button>"
            else
        boton_canonico+= "
        <button class='btn btn-warning archivo_ocultar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-close'>#{I18n.t("file_handler.hide_canonical_document")}</span>
        </button>"

        end
        end
      end
<<HEREDOC
<div class='btn-group btn-group-sm' id='botones_archivo_#{archivo[:id]}'>
  <a class='btn btn-default' href='/file/#{archivo[:id]}/download' role='button'>
    <span class='glyphicon glyphicon-download'>#{I18n.t(:Download)}</span>
  </a>
<button class='btn btn-default btn-sm' data-target='#modalArchivos' data-toggle='modal' type='button' data-name='#{archivo[:archivo_nombre]}' data-pk='#{archivo[:id]}' data-paginas='#{archivo[:paginas]}'>
  <span class='glyphicon glyphicon-eye-open'>#{I18n.t(:View)}</span></button>

#{boton_canonico}
#{boton_rs}
#{boton_eliminar}

        </div>
HEREDOC
      end
    end

end

module Sinatra
  module SinatraManejadorArchivos
    module Helpers
      def get_modal_files
        FileHandler::ModalFiles.new
      end
    end
    def self.registered(app)
      app.helpers SinatraManejadorArchivos::Helpers
    end
  end
  register SinatraManejadorArchivos
end
