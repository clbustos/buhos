module AnalisisTag
# Analiza un tag para la relación entre dos documentos canonicos en una determina revision sistematica
  class Tag_Ref_Cd_Rs
    attr_reader :id, :texto, :positivos, :negativos
    attr_accessor :predeterminado
    def initialize(votos)
      @votos=votos
      @positivos=votos.count {|v| v[:decision]=='yes'}
      @negativos=votos.count {|v| v[:decision]=='no'}
      @id=votos[0][:id]
      @texto=votos[0][:texto]
      @cd_start_id=votos[0][:cd_origen]
      @cd_end_id=votos[0][:cd_destino]
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