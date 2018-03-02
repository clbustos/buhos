class CrossrefDoi < Sequel::Model
  include DOIHelpers
  extend DOIHelpers
  # Dado un doi, descarga la reference desde Crossref si no la tiene
  # y entrega el JSON  correspondiente
  def self.procesar_doi(doi)
    require 'serrano'
    raise 'DOI is nil' if doi.nil?
    co=CrossrefDoi[doi_without_http(doi)]
    if !co or co[:json].nil?
      begin
        resultado=Serrano.works(ids: CGI.escape(doi))
      rescue Serrano::NotFound=>e
        return false
      rescue URI::InvalidURIError
        #$log.info("Malformed URI: #{doi}")
        return false
      end
      if co
        co.update(:json=>resultado.to_json)
      else
        CrossrefDoi.insert(:doi=>doi_without_http(doi),:json=>resultado.to_json)
        co=CrossrefDoi[doi_without_http(doi)]
      end
    end
    co[:json]
  end

  # Entrega el Reference_Integrator::JSON
  # correspondiente a un DOI.
  def self.reference_integrator_json(doi)
    co=self.procesar_doi(doi)
    if(co)
      ReferenceIntegrator::JSON::Reader.parse(co)[0]
    else
      false
    end
  end
end



class BadCrossrefResponseError < StandardError

end
class CrossrefQuery < Sequel::Model

  # Se toma un text y se transforma en un sha256
  def self.generar_query_desde_text(t)
    require 'digest'
    digest=Digest::SHA256.hexdigest t
    cq=CrossrefQuery[digest]

    if !cq
      url="https://search.crossref.org/dois?q=#{CGI.escape(t)}"
      uri = URI(url)
      res = Net::HTTP.get_response(uri)
      $log.info(res)
      if res.code!="200"
        raise BadCrossrefResponseError, "El text #{t} no entrego una respuesta adecuada. Fue #{res.code}, #{res.body}"
      end
      json_raw = res.body
      CrossrefQuery.insert(:id=>digest.force_encoding(Encoding::UTF_8),:query=>t.force_encoding(Encoding::UTF_8),:json=>json_raw.force_encoding(Encoding::UTF_8))
    else
      json_raw=cq[:json]
    end
    JSON.parse(json_raw)
  end

end