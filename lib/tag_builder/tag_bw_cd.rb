# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
#
module TagBuilder
  # Provides information and HTML for tags related to relations between canonical documents
  class TagBwCd
    include TagMixin
    def initialize(votos)
      initialize_common(votos)
      @cd_start_id=votos[0][:cd_start]
      @cd_end_id=votos[0][:cd_end]
    end

    def url_t(action)
      "/tags/cd_start/#{@cd_start_id}/cd_end/#{@cd_end_id}/rs/#{@rs_id}/#{action}_tag"
    end

    def button_change_html(action, glyphicon_class,number)
      "<button class='btn btn-default boton_accion_tag_cd_rs_ref' cd_start-pk='#{@cd_start_id}' cd_end-pk='#{@cd_end_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t(action)}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
    end

  end
end