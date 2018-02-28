require 'digest'
# Qué es una referencia?
# Es una cita de un texto a otro. Su representación se basa en el texto,
# aunque el DOI u otra forma de identificación deberían tener preferencia

class Referencia < Sequel::Model

  include DOIHelpers
  extend DOIHelpers

  many_to_many :registros
  def self.get_by_text(text)
    dig=Digest::SHA256.hexdigest text
    Referencia[dig]
  end
  def self.get_by_text_and_doi(text,doi,create=false)
    dig=Digest::SHA256.hexdigest text
    if doi
      doi=doi_sin_http(doi)
      ref=Referencia.where(:id=>dig,:doi=>doi).first
    else
      ref=Referencia[dig]
    end
    if create and !ref
      Referencia.insert(:id=>dig,:texto=>text,:doi=>doi)
      ref=Referencia[dig]
    end
    ref
  end

  def crossref_query
    Crossref_Query.generar_query_desde_texto( self[:texto] )
  end

  def buscar_similares(d=nil,sin_canonico=true)
    require 'levenshtein-ffi'

    canonico_sql= sin_canonico ? " AND canonico_documento_id IS NULL ": ""

    distancias=Referencia.where(Sequel.lit("id!='#{self[:id]}' #{canonico_sql}")).map {|v|
      {
          :id=>v[:id],
          :canonico_documento_id=>v[:canonico_documento_id],
          :texto=>v[:texto],
          :distancia=>Levenshtein.distance(v[:texto],self[:texto])
      }

    }
    if !d.nil?
      distancias=distancias.find_all {|v| v[:distancia]<=d}
    end
    distancias.sort {|a,b| a[:distancia]<=>b[:distancia]}
  end


  def add_doi(doi_n)
    #$log.info("Agregar #{doi_n} a #{self[:id]}")
    status=Result.new

    crossref_doi=Crossref_Doi.procesar_doi(doi_n)

    unless crossref_doi
      status.error("No puedo procesar DOI #{doi_n}")
      return status
    end

    $db.transaction do
      ##$log.info(co)
      if self[:doi]==doi_n
        status.info("Ya agregado DOI para referencia #{self[:id]}")
      else
        self.update(:doi=>doi_sin_http(doi_n))
        status.success("Se agrega DOI #{doi_n} para referencia #{self[:id]}")
      end

      if self[:canonico_documento_id].nil?
        can_doc=Canonico_Documento[:doi=>doi_sin_http(doi_n)]
        if can_doc
          self.update(:canonico_documento_id=>can_doc[:id])
          status.info("Agregado a documento canónico #{can_doc[:id]} ya existente")
        else # No existe el canónico, lo debo crear
          integrator=Crossref_Doi.reference_integrator_json(doi)
          ##$log.info(integrator)
          fields = [:title,:author,:year,:journal, :volume, :pages, :doi, :journal_abbr,:abstract]
          fields_update=fields.inject({}) {|ac,v|
            ac[v]= integrator.send(v); ac;
          }

          # En casos muy raros no está el año. Tengo que reportar error, no más
          if fields_update[:year].nil?
            status.error("El DOI #{doi} no tiene año. Extraño, pero tengo que cancelar misión")
          else
            can_doc_id=Canonico_Documento.insert(fields_update)
            self.update(:canonico_documento_id=>can_doc_id)
            status.success("Agregado un nuevo documento canónico #{can_doc_id}: #{integrator.ref_apa_6}")
          end
        end
        $db.after_rollback {
          status=Result.new
          status.error("Rollback en agregar doi para referencia #{self[:id]}")
        }
      end
    end

    status
  end


end