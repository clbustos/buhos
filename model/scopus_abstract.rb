class Scopus_Abstract < Sequel::Model
  def self.get(tipo, id)
    if tipo.to_s=='eid'
      Scopus_Abstract[id]
    elsif tipo.to_s=='doi'
      Scopus_Abstract.where(:doi => id).first
    else
      raise Buhos::NoScopusMethodError, ::I18n.t("error.no_scopus_method", type:type)
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
    cd=CanonicalDocument[cd_id]
    #$log.info("Procesando scopus para CD:#{cd.id}")
    if cd.scopus_id
      tipo='eid'
      id=cd.scopus_id.gsub("eid=", "")
    elsif cd.doi
      tipo='doi'
      id=cd.doi
    else
      result.error(I18n::t("scopus_abstract.cant_obtain_identificator_suitable_for_scopus", cd_title:cd[:title]))
      return result
    end


    sa=Scopus_Abstract.get(tipo, id)

    if !sa
      sr=ScopusRemote.new
      xml=sr.xml_abstract_by_id(id, tipo)
      if xml
        agregar_desde_xml(xml)
      else
        result.error(I18n::t("scopus_abstract.cant_obtain_scopus_error", cd_title:cd[:title], sr_error: sr.error))
        return result
      end
    else
      xml=Scopus.process_xml(sa[:xml])
    end



    if xml.abstract.to_s==""
      result.error(I18n::t("scopus_abstract.no_scopus_abstract",cd_title:cd[:title]))
    elsif cd.abstract.to_s==""
      cd.update(:abstract => xml.abstract)
      result.success(I18n::t("scopus_abstract.updated_abstract",cd_title:cd[:title]))
    end

    result
  end
end