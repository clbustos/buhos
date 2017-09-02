class Canonico_Documento < Sequel::Model

  one_to_many :referencias
  one_to_many :registros

  include MetodosReferencia
  def crossref_integrator
    if self.doi
      Crossref_Doi.reference_integrator_json(self.doi)
    else
      false
    end
  end
  def buscar_referencias_similares(d=nil,sin_canonico=true)
    require 'levenshtein-ffi'
    d_max=[ref_apa_6.length,self[:title].length].max

    d=d_max if d.nil? or d>d_max
    canonico_sql= sin_canonico ? " OR canonico_documento_id IS NULL ": ""

    distancias=Referencia.where("canonico_documento_id!='#{self[:id]}' #{canonico_sql}").map {|v|
      dis_apa_6=Levenshtein.distance(v[:texto],ref_apa_6)
      dis_solo_titulo=Levenshtein.distance(v[:texto],self[:title])
      distancia=[dis_apa_6,dis_solo_titulo].min
      {
          :id=>v[:id],
          :canonico_documento_id=>v[:canonico_documento_id],
          :texto=>v[:texto],
          :distancia=>distancia
      }

    }
    if !d.nil?
      distancias=distancias.find_all {|v| v[:distancia]<=d}
    end
    distancias.sort {|a,b| a[:distancia]<=>b[:distancia]}
  end

end
