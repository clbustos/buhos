require_relative 'tag_mixin.rb'
module TagBuilder

  class TagInCd
    include TagMixin
    attr_reader :id, :texto, :positivos, :negativos
    attr_accessor :predeterminado
    def initialize(votos)
      initialize_common(votos)

      @cd_id=votos[0][:canonico_documento_id]

    end

    def button_change_html(url_t, glyphicon_class,number)
      "<button class='btn btn-default boton_accion_tag_cd_rs' cd-pk='#{@cd_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
    end
    def button_same_html(btn_class, glyphicon_class, number)
      "<button class='btn btn-#{btn_class}'><span class='glyphicon glyphicon-#{glyphicon_class}'></span> <span class='badge '>#{number}</span></button>"
    end

    def boton_positivo_html(ru)
      if ru.nil? or ru[:decision]=='no'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/approve_tag"
        button_change_html(url_t, "plus",positivos)
      else
        button_same_html("success","plus",positivos)
      end
    end
    def boton_negativo_html(ru)
      if ru.nil? or ru[:decision]=='yes'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/reject_tag"
        button_change_html(url_t, "minus",negativos)
      else
        button_same_html("danger","minux",negativos)
      end
    end

  end
end