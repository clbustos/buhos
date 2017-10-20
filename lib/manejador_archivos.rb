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
        <h4 class='modal-title' id='myModalLabel'>Archivo</h4>
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
              <button class='btn btn-default' data-dismiss='modal' type='button'>Close</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
HEREDOC
      end
      def botones(archivo,cd_id=nil)
        boton_canonico=""
        if cd_id
          acd=Archivo_Cd[:archivo_id=>archivo[:id], :canonico_documento_id=>cd_id]
          if acd
            if acd[:no_considerar]
        boton_canonico= "
        <button class='btn btn-default archivo_mostrar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-open'>Agregar</span>
        </button>"
            else
        boton_canonico= "
        <button class='btn btn-warning archivo_ocultar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-eye-close'>Ocultar</span>
        </button>"

        end
        end
      end
<<HEREDOC
<div class='btn-group btn-group-sm' id='botones_archivo_#{archivo[:id]}'>
<a class='btn btn-default' href='/archivo/#{archivo[:id]}/descargar' role='button'>
<span class='glyphicon glyphicon-download'>Descargar</span>
</a>
<button class='btn btn-default btn-sm' data-target='#modalArchivos' data-toggle='modal' type='button' data-pk='#{archivo[:id]}' data-paginas='#{archivo[:paginas]}'>
  <span class='glyphicon glyphicon-eye-open'>Ver</span></button>
<button class='btn btn-danger archivo_desasignar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
        <span class='glyphicon glyphicon-remove'>Desasignar</span>
        </button>
#{boton_canonico}
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
