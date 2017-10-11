# Lo relacionado con analizar tags
module AnalisisTag
  def self.tag_en_cd_rs(revision,cd)
    Contenedor_Tags_En_Cd_Rs.new(revision,cd)
  end
  # Analiza un tag para un determinado documento canonico en una determina revision sistematica
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
    def boton_positivo_html(ru)
      if ru.nil? or ru[:decision]=='no'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/aprobar_tag"
        "<button class='btn btn-default boton_accion_tag_cd_rs' cd-pk='#{@cd_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-plus'></span> <span class='badge '>#{positivos}</span></button>"
      else
        "<button class='btn btn-success'><span class='glyphicon glyphicon-plus'></span> <span class='badge '>#{positivos}</span></button>"
      end
    end
    def boton_negativo_html(ru)
      if ru.nil? or ru[:decision]=='yes'
        url_t="/tags/cd/#{@cd_id}/rs/#{@rs_id}/rechazar_tag"
        "<button class='btn btn-default boton_accion_tag_cd_rs' cd-pk='#{@cd_id}' rs-pk='#{@rs_id}' tag-pk='#{@tag_id}' data-url='#{url_t}'><span class='glyphicon glyphicon-minus'></span> <span class='badge '>#{negativos}</span></button>"
      else
        "<button class='btn btn-danger'><span class='glyphicon glyphicon-minus'></span> <span class='badge '>#{negativos}</span></button>"
      end
    end
  end
  class Contenedor_Tags_En_Cd_Rs
    include Enumerable
    attr_reader :tag_cd_rs
    def initialize(revision,cd)

      @revision=revision
      @cd=cd
      # Tags ya elegidos
      @tag_cd_rs=Tag_En_Cd.tags_rs_cd(revision,cd).to_hash_groups(:tag_id)
      # Ahora, los tags por defecto que falta por elegir
      @predeterminados=[]

      @revision.t_clases_documentos.each do |clase|
        clase.tags.each do |tag|
          @predeterminados.push(tag.id)
          unless @tag_cd_rs.keys.include? tag.id
            @tag_cd_rs[tag.id]=[{:revision_sistematica_id=>revision.id, :canonico_documento_id=>cd.id,:tag_id=>tag.id,:texto=>tag.texto,:usuario_id=>0,:decision=>nil}]
          end
        end
      end
    end
    def tags_ordenados
      @tag_cd_rs.sort {|a,b|
        tag_1=a[1][0]
        tag_2=b[1][0]
        if @predeterminados.include? tag_1[:tag_id] and !@predeterminados.include? tag_2[:tag_id]
          +1
        elsif !@predeterminados.include? tag_1[:tag_id] and @predeterminados.include? tag_2[:tag_id]
          -1
        else
          tag_1[:texto]<=>tag_2[:texto]
        end
      }
    end
    def each
      tags_ordenados.each do |v|

        recs=Tag_En_Cd_Rs.new(v[1])
        recs.predeterminado=@predeterminados.include? v[0]
        yield recs
      end
    end

  end
end