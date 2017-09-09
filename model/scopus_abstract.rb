class Scopus_Abstract < Sequel::Model
  def self.get(tipo, id)
    if tipo.to_s=='eid'
      Scopus_Abstract[id]
    elsif tipo.to_s=='doi'
      Scopus_Abstract.where(:doi => id).first
    else
      raise "Tipo #{tipo} no reconocido"
    end
  end

  def self.agregar_desde_xml(xml)
    sa=Scopus_Abstract[xml.eid]
    if !sa
      Scopus_Abstract.insert(:id => xml.eid, :xml => xml.xml.to_s, :doi => xml.doi)
    end

  end

  def self.obtener_abstract_cd(cd_id)
    result=Result.new
    cd=Canonico_Documento[cd_id]
    #$log.info("Procesando scopus para CD:#{cd.id}")
    if cd.scopus_id
      tipo='eid'
      id=cd.scopus_id.gsub("eid=", "")
    elsif cd.doi
      tipo='doi'
      id=cd.doi
    else
      result.error("No hay como identificar en Scopus canónico #{cd[:id]}")
      return result
    end


    sa=Scopus_Abstract.get(tipo, id)

    if !sa
      sr=ScopusRemote.new
      xml=sr.xml_abstract_by_id(id, tipo)
      if xml
        agregar_desde_xml(xml)

      else

        result.error("No se pudo obtener el Scopus para CD #{cd[:id]} : #{sr.error}")
        return result
      end
    else
      xml=Scopus.process_xml(sa[:xml])
    end

    if cd.abstract.to_s=="" and xml.abstract.to_s!=""
      cd.update(:abstract => xml.abstract)
      result.success("Actualizado abstract via Scopus")
    end

    result
  end
end