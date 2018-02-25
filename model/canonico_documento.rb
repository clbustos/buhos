class Canonico_Documento < Sequel::Model
  # Corresponde a las referencias que tienen como canónico a este objeto
  one_to_many :referencias
  one_to_many :registros

  include MetodosReferencia
  # Cada documento genérico realiza referencias. ¿A quién las hace?

  def referencias_realizadas
    ids=$db["SELECT ref.id FROM registros r INNER JOIN referencias_registros rr ON r.id=rr.registro_id INNER JOIN referencias ref ON rr.referencia_id=ref.id WHERE r.canonico_documento_id=?", self[:id]].map(:id)
    Referencia.where(:id => ids)
  end

  # Une los documentos canonicos, de acuerdo al id
  def self.unir(pks)
    pk_id=pks[0]
    pk_otros=pks[1...pks.length]
    resultado=true
    $db.transaction(:rollback => :reraise) do
      columnas=Canonico_Documento.columns
      columnas.delete(:id)

      cds=Canonico_Documento.where(:id => pks)
      fields=columnas.inject({}) {|ac, v| ac[v]=nil; ac}
      cds.each do |cd|
        columnas.find_all {|col| fields[col].nil? or fields[col]==""}.each {|col|
          fields[col]=cd[col]
        }
      end
      Canonico_Documento[pk_id].update(fields)
      Registro.where(:canonico_documento_id => pks).update(:canonico_documento_id => pk_id)
      Referencia.where(:canonico_documento_id => pks).update(:canonico_documento_id => pk_id)
      $db[:canonicos_documentos_autores].where(:canonico_documento_id => pks).update(:canonico_documento_id => pk_id)
      Canonico_Documento.where(:id => pk_otros).delete
      $db.after_rollback {
        resultado=false
      }
    end
    resultado
  end

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

    distancias=Referencia.where(Sequel.lit("canonico_documento_id!='#{self[:id]}' #{canonico_sql}")).map {|v|
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
