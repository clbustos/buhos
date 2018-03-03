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
# TagMixin for common methods on tags for cd and tags for relation between cd
#
# Alternatives: Maybe a Delegator pattern should work. All tag related actions
# are managed by a common Class (TagBuilder) and the differences between
# cd tags and relations tags are mannaged by a object inside the class
#
module TagMixin

  def initialize_common(votos)
    @votos=votos
    @positivos=votos.count {|v| v[:decision]=='yes'}
    @negativos=votos.count {|v| v[:decision]=='no'}
    @id=votos[0][:id]
    @text=votos[0][:text]
    @rs_id=votos[0][:systematic_review_id]
    @tag_id=votos[0][:tag_id]
  end

  def botones_html(user_id)
    ru = resultado_usuario(user_id)
    "
<div class='btn-group btn-group-xs'>
  #{boton_positivo_html(ru)}
    #{boton_negativo_html(ru)}
</div>"
  end

  def resultado_usuario(user_id)
    @votos.find {|v| v[:user_id] == user_id}
  end

  def sin_votos?
    positivos + negativos == 0
  end

  def mostrar
    @predeterminado or @positivos > 0
  end

  def boton_positivo_html
    raise "To implement"
  end


  def boton_negativo_html
    raise "To implement"
  end
end
