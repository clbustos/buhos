class NBayes_RS
  attr_reader :nbayes_rtr
  STOPWORDS=%w{the an a with we dont to in that these those from each @ i}

  def initialize(rs)
    require 'nbayes'
    require 'lingua/stemmer'
    @rs=rs
    @nbayes_rtr=nbayes_rtr_calculo
  end

  def get_stemmer(texto)
    res=Lingua.stemmer(texto.split(/[\s-]+/).map {|vv| vv.downcase.gsub(/[[:punct:]]/, "")}.find_all {|v| !STOPWORDS.include? v})
    res.is_a?(Array) ? res : [res]
  end

  def nbayes_rtr_calculo
    nbayes = NBayes::Base.new
    nombres = (Canonico_Documento.select(:title, :abstract, :journal, :resolucion).join_table(:inner, :resoluciones, canonico_documento_id: :id).where(:revision_sistematica_id => @rs.id)).map {|v| {:nombre => get_stemmer("#{v[:title]} #{v[:abstract]}")+[v[:journal]], :resolucion => v[:resolucion]}}
    nombres.each do |n|
      nbayes.train(n[:nombre], n[:resolucion])
    end
    #$log.info(nbayes)
    nbayes
  end

  private :nbayes_rtr_calculo

  # Entrega la clasificación para un cd_id específico
  def cd_resultado(cd_id)
    cd=@rs.cd_hash[cd_id]
    tokens=get_stemmer("#{cd[:title]} #{cd[:abstract]}")+[cd[:journal]]
    res={"yes" => 0, "no" => 0}.merge(nbayes_rtr.classify(tokens))
    #$log.info(res)
    res
  end
end