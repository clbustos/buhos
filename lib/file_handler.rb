# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module FileHandler
  # Maneja el javascript para ver files de forma modal

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
  <input type='hidden' name='systematic_review_id' value='#{rs_id}' />
  <input type='hidden' name='canonical_document_id' value='#{cd_id}' />
  <div class='form-group'>
    <input type='file' name='files[]'/>
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
          acd=FileCd[:file_id=>archivo[:id], :canonical_document_id=>cd_id]
          if acd
            boton_canonico="
          <button class='btn btn-warning archivo_desasignar_cd' data-aid='#{archivo[:id]}' data-cdid='#{cd_id}' role='button'>
          <span class='glyphicon glyphicon-remove'>#{I18n.t("file_handler.unassign_canonical_document")}</span>
        </button>"
            if acd[:not_consider]
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
<button class='btn btn-default btn-sm' data-target='#modalArchivos' data-toggle='modal' type='button' data-name='#{archivo[:filename]}' data-pk='#{archivo[:id]}' data-pages='#{archivo[:pages]}'>
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
