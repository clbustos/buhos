# encoding: UTF-8


class Buhos::Configuration < Sequel::Model
  def self.set(id,valor)
    conf=Buhos::Configuration[id]
    if conf.nil?
      Buhos::Configuration.insert(:id=>id,:valor=>valor)
    else
      Buhos::Configuration[id].update(:valor=>valor)
    end
  end
  def self.get(id)
    conf=Buhos::Configuration[id]
    if conf.nil?
      nil
    else
      conf[:valor]
    end
  end
end



class Sr_Taxonomy < Sequel::Model

end

class Sr_Taxonomy_Category < Sequel::Model

end

class Systematic_Review_SRTC < Sequel::Model

end


class GroupsUser < Sequel::Model
  many_to_one :user
  many_to_one :group
end


class RecordsReferences < Sequel::Model

end




class BibliographicDatabase < Sequel::Model
  def self.name_a_id_h
    $db['SELECT * FROM bibliographic_databases'].as_hash(:name, :id)
  end
  def self.id_a_name_h
    $db['SELECT * FROM bibliographic_databases'].as_hash(:id, :name)
  end
end

