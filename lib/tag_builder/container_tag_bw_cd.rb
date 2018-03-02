module TagBuilder
  # Container for tags between canonical documents
  class ContainerTagBwCd
    include Enumerable
    attr_reader :tag_cd_rs_ref
    def initialize(revision,cd_start, cd_end)

      @review = revision
      @cd_start = cd_start
      @cd_end   = cd_end
      # Tags ya elegidos
      @tag_cd_rs_ref=::TagBwCd.tags_rs_cd(revision,cd_start, cd_end).to_hash_groups(:tag_id)
      # Ahora, los tags por defecto que falta por elegir
      @predeterminados=[]

      @review.t_clases_documentos.each do |clase|
        clase.tags.each do |tag|
          @predeterminados.push(tag.id)
          unless @tag_cd_rs_ref.keys.include? tag.id
            @tag_cd_rs_ref[tag.id]=[{:systematic_review_id=>revision.id, :cd_start=>cd_start.id, cd_end=>cd_end.id, :tag_id=>tag.id,:text=>tag.text,:user_id=>0,:decision=>nil}]
          end
        end
      end
    end

    def tags_orderados
      @tag_cd_rs_ref.sort {|a,b|
        tag_1=a[1][0]
        tag_2=b[1][0]
        if @predeterminados.include? tag_1[:tag_id] and !@predeterminados.include? tag_2[:tag_id]
          +1
        elsif !@predeterminados.include? tag_1[:tag_id] and @predeterminados.include? tag_2[:tag_id]
          -1
        else
          tag_1[:text]<=>tag_2[:text]
        end
      }
    end

    def each
      tags_orderados.each do |v|
        recs=::TagBuilder::TagBwCd.new(v[1])
        recs.predeterminado=@predeterminados.include? v[0]
        yield recs
      end
    end

  end
end