# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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
  attr_reader :id, :text, :positivos, :negativos
  attr_accessor :predeterminado

  def initialize_common(votos)
    @votos=votos
    @positivos=votos.count {|v| v[:decision]=='yes'}
    @negativos=votos.count {|v| v[:decision]=='no'}
    @id=votos[0][:id]
    @text=votos[0][:text]
    @rs_id=votos[0][:systematic_review_id]
    @tag_id=votos[0][:tag_id]
  end

  def buttons_html(user_id)
    ru = resultado_usuario(user_id)
    "
<div class='btn-group btn-group-xs'>
  #{button_positive_html(ru)}
    #{button_negative_html(ru)}
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

  def button_same_html(btn_class, glyphicon_class, number)
    "<button class='btn btn-#{btn_class}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
  end

  def button_positive_html(ru)
    if ru.nil? or ru[:decision]=='no'
      button_change_html(:approve, :plus, positivos)
    else
      button_same_html(:success, :plus, positivos)
    end
  end

  def button_negative_html(ru)
    if ru.nil? or ru[:decision]=='yes'
      button_change_html(:reject, :minus, negativos)
    else
      button_same_html(:danger, :minus, negativos)
    end
  end

end