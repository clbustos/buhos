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
    @texto=votos[0][:texto]
    @rs_id=votos[0][:revision_sistematica_id]
    @tag_id=votos[0][:tag_id]
  end

  def botones_html(usuario_id)
    ru = resultado_usuario(usuario_id)
    "
<div class='btn-group btn-group-xs'>
  #{boton_positivo_html(ru)}
    #{boton_negativo_html(ru)}
</div>"
  end

  def resultado_usuario(usuario_id)
    @votos.find {|v| v[:usuario_id] == usuario_id}
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
