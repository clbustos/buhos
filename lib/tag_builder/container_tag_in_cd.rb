module TagBuilder
  class ContainerTagInCd
    include Enumerable
    attr_reader :tag_cd_rs
    def initialize(revision,cd)

      @review=revision
      @cd=cd
      # Tags ya elegidos
      @tag_cd_rs=::TagInCd.tags_rs_cd(revision,cd).to_hash_groups(:tag_id)
      # Ahora, los tags por defecto que falta por elegir
      @predeterminados=[]

      @review.t_clases_documentos.each do |clase|
        clase.tags.each do |tag|
          @predeterminados.push(tag.id)
          unless @tag_cd_rs.keys.include? tag.id
            @tag_cd_rs[tag.id]=[{:systematic_review_id=>revision.id, :canonical_document_id=>cd.id,:tag_id=>tag.id,:text=>tag.text,:user_id=>0,:decision=>nil}]
          end
        end
      end
    end
    def tags_orderados
      @tag_cd_rs.sort {|a,b|
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
        recs=::TagBuilder::TagInCd.new(v[1])
        recs.predeterminado=@predeterminados.include? v[0]
        yield recs
      end
    end

    end
end