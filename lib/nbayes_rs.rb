class NBayes_RS
  attr_reader :nbayes_rtr
  STOPWORDS=%w{the an a with we dont to in that these those from each @ i}

  def initialize(rs)
    require 'nbayes'
    require 'lingua/stemmer'
    @rs=rs
    @nbayes_rtr=nbayes_rtr_calculo
  end

  def get_stemmer(text)
    res=Lingua.stemmer(text.split(/[\s-]+/).map {|vv| vv.downcase.gsub(/[[:punct:]]/, "")}.find_all {|v| !STOPWORDS.include? v})
    res.is_a?(Array) ? res : [res]
  end

  def nbayes_rtr_calculo
    nbayes = NBayes::Base.new
    names = (CanonicalDocument.select(:title, :abstract, :journal, :resolution).join_table(:inner, :resolutions, canonical_document_id: :id).where(:systematic_review_id => @rs.id)).map {|v| {:name => get_stemmer("#{v[:title]} #{v[:abstract]}")+[v[:journal]], :resolution => v[:resolution]}}
    names.each do |n|
      nbayes.train(n[:name], n[:resolution])
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