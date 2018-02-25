class CategorizerSr
  attr_reader :categorias_cd_id
  STOPWORDS=%w{the an a with we dont to in that these those from each @ i it other how is are why}

  def initialize(rs,model=nil)
    require 'categorize'
    require 'lingua/stemmer'
    @rs=rs

    if(model.nil?)
      @model = Categorize::Models::BagOfWords.new

      @model.max_buckets = @rs.cd_todos_id.length>0 ? Math.log(@rs.cd_todos_id.length).floor*2 : 1
    else
      @model.min_support = 0.01
      @model=model
    end
    categorizador_calculo
  end

  def get_stemmer_text(texto)
    res=Lingua.stemmer(texto.split(/[\s-]+/).map {|vv| vv.downcase.gsub(/[[:punct:]]/, "")}.find_all {|v| !STOPWORDS.include? v})
    res.is_a?(Array) ? res.join(" ") : res
  end

  def categorizador_calculo

    @cd_hash=@rs.cd_hash
    titulos=@cd_hash.map {|key,v|  get_stemmer_text("#{v[:title]}")}
    @categorias=Categorize::Model.make_model("busqueda",titulos , @model)
    #$log.info(@categorias)
    @categorias_cd_id=@categorias.inject({}) {|ac,v|
      ac[v[0]]=v[1].map{|orden_i|  @cd_hash.keys[orden_i] }
      ac
    }
    @cd_id_categorias={}
    @categorias_cd_id.each do |cat,cd_ids|
      cd_ids.each do |cd_id|
        @cd_id_categorias[cd_id]=cat
      end
    end
  end

  private :categorizador_calculo
  def cd_categoria(cd_id)
    @cd_id_categorias[cd_id]
  end

end