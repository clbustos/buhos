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
require_relative 'tag_mixin.rb'
module TagBuilder
# Analiza un tag para la relación entre dos documentos canonicos en una determina revision sistematica
  class TagBwCd
    include TagMixin
    attr_reader :id, :text, :positivos, :negativos
    attr_accessor :predeterminado
    def initialize(votos)
      initialize_common(votos)
      @cd_start_id=votos[0][:cd_start]
      @cd_end_id=votos[0][:cd_end]

    end
    def boton_positivo_html(ru)
      if ru.nil? or ru[:decision]=='no'
        url_t="/tags/cd_start/#{@cd_start_id}/cd_end/#{@cd_end_id}/rs/#{@rs_id}/approve_tag"
        "<button class='btn btn-default boton_accion_tag_cd_rs_ref' cd_start-pk='#{@cd_start_id}' cd_end-pk='#{@cd_end_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-plus'></span> <span class='badge '>#{positivos}</span></button>"
      else
        "<button class='btn btn-success'><span class='glyphicon glyphicon-plus'></span> <span class='badge '>#{positivos}</span></button>"
      end
    end
    def boton_negativo_html(ru)
      if ru.nil? or ru[:decision]=='yes'
        url_t="/tags/cd_start/#{@cd_start_id}/cd_end/#{@cd_end_id}/rs/#{@rs_id}/reject_tag"
        "<button class='btn btn-default boton_accion_tag_cd_rs_ref' cd_start-pk='#{@cd_start_id}' cd_end-pk='#{@cd_end_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-minus'></span> <span class='badge '>#{negativos}</span></button>"
      else
        "<button class='btn btn-danger'><span class='glyphicon glyphicon-minus'></span> <span class='badge '>#{negativos}</span></button>"
      end
    end
  end
end