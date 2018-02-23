module AnalisisTag
  class Tag_En_Cd_Rs
    attr_reader :id, :texto, :positivos, :negativos
    attr_accessor :predeterminado
    def initialize(votos)
      @votos=votos
      @positivos=votos.count {|v| v[:decision]=='yes'}
      @negativos=votos.count {|v| v[:decision]=='no'}
      @id=votos[0][:id]
      @texto=votos[0][:texto]
      @cd_id=votos[0][:canonico_documento_id]
      @rs_id=votos[0][:revision_sistematica_id]
      @tag_id=votos[0][:tag_id]
    end
    def mostrar
      @predeterminado or @positivos>0
    end
    def sin_votos?
      positivos+negativos==0
    end
    def resultado_usuario(usuario_id)
      @votos.find {|v| v[:usuario_id]==usuario_id}
    end
    def botones_html(usuario_id)
      ru=resultado_usuario(usuario_id)
      "
<div class='btn-group btn-group-xs'>
  #{boton_positivo_html(ru)}
  #{boton_negativo_html(ru)}
</div>"
    end

    def button_change_html(url_t, glyphicon_class,number)
      "<button class='btn btn-default boton_accion_tag_cd_rs' cd-pk='#{@cd_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
    end
    def button_same_html(btn_class, glyphicon_class, number)
      "<button class='btn btn-#{btn_class}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
    end

    def boton_positivo_html(ru)
      if ru.nil? or ru[:decision]=='no'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/aprobar_tag"
        button_change_html(url_t, "plus",positivos)
      else
        button_same_html("success","plus",positivos)
      end
    end
    def boton_negativo_html(ru)
      if ru.nil? or ru[:decision]=='yes'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/rechazar_tag"
        button_change_html(url_t, "minus",negativos)
      else
        button_same_html("danger","minux",negativos)
      end
    end

  end
end