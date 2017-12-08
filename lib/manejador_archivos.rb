module ManejadorArchivos
  # Maneja el javascript para ver archivos de forma modal

    class ModalArchivos
      def initialize

      end
      def javascript_header
        "<script src='/js/modal_archivos.js'></script>"
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
      <div class='modal-body'></div>
      <div class='modal-footer'>
        <div class='row'>
          <div class='col-md-6' id='modal_cuenta_paginas'>
            Página x de x
          </div>
          <div class='col-md-6'>
            <div class='btn-group btn-group-sm'>
              <button class='btn btn-default' id='boton_pagina_menos' type='button'>
                <span class='glyphicon glyphicon-arrow-left'></span>
              </button>
              <button class='btn btn-default' id='boton_pagina_mas' type='button'>
                <span class='glyphicon glyphicon-arrow-right'></span>
              </button>
              <button class='btn btn-default' data-dismiss='modal' type='button'>#{I18n.t(:Close)}</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
HEREDOC
      end
      def cargador_archivo(rs_id,cd_id)
        "<form method='post' action='/revision/archivos/agregar' enctype='multipart/form-data'>
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
          <span class='glyphicon glyphicon-remove'>#{I18n.t(:Delete_file)}</span>
        </button>"
        end
        if rs_id
          boton_rs="
          <button class='btn btn-warning archivo_desasignar_rs' data-aid='#{archivo[:id]}' data-rsid='#{rs_id}' role='button'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t(:Delete_from_systematic_review)}</span>
        </button>
        "
        end
        if cd_id
          acd=Archivo_Cd[:archivo_id=>archivo[:id], :canonico_documento_id=>cd_id]
          if acd
            boton_canonico="
          <button class='btn btn-warning archivo_desasignar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t(:Unassign_from_canonical_document)}</span>
        </button>"
            if acd[:no_considerar]
        boton_canonico+= "
        <button class='btn btn-default archivo_mostrar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-open'>#{I18n.t(:Show_on_canonical_document)}</span>
        </button>"
            else
        boton_canonico+= "
        <button class='btn btn-warning archivo_ocultar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-close'>#{I18n.t(:Hide_from_canonical_document)}</span>
        </button>"

        end
        end
      end
<<HEREDOC
<div class='btn-group btn-group-sm' id='botones_archivo_#{archivo[:id]}'>
<a class='btn btn-default' href='/archivo/#{archivo[:id]}/descargar' role='button'>
<span class='glyphicon glyphicon-download'>#{I18n.t(:Download)}</span>
</a>
<button class='btn btn-default btn-sm' data-target='#modalArchivos' data-toggle='modal' type='button' data-pk='#{archivo[:id]}' data-paginas='#{archivo[:paginas]}'>
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
      def get_modalarchivos
        ManejadorArchivos::ModalArchivos.new
      end
    end
    def self.registered(app)
      app.helpers SinatraManejadorArchivos::Helpers
    end
  end
  register SinatraManejadorArchivos
end
