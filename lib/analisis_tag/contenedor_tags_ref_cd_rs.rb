module AnalisisTag
  class Contenedor_Tags_Ref_Cd_Rs
    include Enumerable
    attr_reader :tag_cd_rs_ref
    def initialize(revision,cd_start, cd_end)

      @revision = revision
      @cd_start = cd_start
      @cd_end   = cd_end
      # Tags ya elegidos
      @tag_cd_rs_ref=Tag_En_Referencia_Entre_Cn.tags_rs_cd(revision,cd_start, cd_end).to_hash_groups(:tag_id)
      # Ahora, los tags por defecto que falta por elegir
      @predeterminados=[]

      @revision.t_clases_documentos.each do |clase|
        clase.tags.each do |tag|
          @predeterminados.push(tag.id)
          unless @tag_cd_rs_ref.keys.include? tag.id
            @tag_cd_rs_ref[tag.id]=[{:revision_sistematica_id=>revision.id, :cd_origen=>cd_start.id, cd_destino=>cd_end.id, :tag_id=>tag.id,:texto=>tag.texto,:usuario_id=>0,:decision=>nil}]
          end
        end
      end
    end

    def tags_ordenados
      @tag_cd_rs_ref.sort {|a,b|
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
        recs=Tag_Ref_Cd_Rs.new(v[1])
        recs.predeterminado=@predeterminados.include? v[0]
        yield recs
      end
    end

  end
end