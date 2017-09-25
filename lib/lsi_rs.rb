# Clse que clasifica, usando LSI, los distintos artículos
# Es muy lenta, así que debe usarse con no muchos artículos
class LSI_RS
  attr_reader :lsi_rtr
  STOPWORDS=%w{the an a with we dont to in that these those from each @ i}

  def initialize(rs)
    require 'classifier-reborn'
    @rs=rs
    @lsi_rtr=lsi_calculo
  end

  def lsi_calculo
    lsi = ClassifierReborn::LSI.new
    nombres = (Canonico_Documento.select(:title, :abstract, :journal, :resolucion).join_table(:inner, :resoluciones, canonico_documento_id: :id).where(:revision_sistematica_id => @rs.id)).map {|v| {:nombre => "#{v[:title]}. #{v[:abstract]}", :resolucion => v[:resolucion]}}
    nombres.each do |n|
      lsi.add_item n[:nombre], n[:resolucion]
    end
    $log.info(lsi)
    lsi
  end

  private :lsi_calculo

  # Entrega la clasificación para un cd_id específico
  def cd_nbayes_rtr(cd_id)
    cd=@rs.cd_hash[cd_id]
    res=lsi.classify "#{cd[:title]}.#{cd[:abstract]}"
    $log.info(res)
    res
  end
end