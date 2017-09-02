# encoding: UTF-8


class Configuracion < Sequel::Model
  def self.set(id,valor)
    conf=Configuracion[id]
    if conf.nil?
      Configuracion.insert(:id=>id,:valor=>valor)
    else
      Configuracion[id].update(:valor=>valor)
    end
  end
  def self.get(id)
    conf=Configuracion[id]
    if conf.nil?
      nil
    else
      conf[:valor]
    end
  end
end


class Configuracion < Sequel::Model
end

class TrsFoco < Sequel::Model
end

class TrsDestinatario < Sequel::Model
end

class TrsObjetivo  < Sequel::Model
end
class TrsPerspectiva  < Sequel::Model
end

class TrsCobertura  < Sequel::Model
end
class TrsOrganizacion  < Sequel::Model
end





class Usuario < Sequel::Model

end

class Grupo < Sequel::Model
  many_to_many :usuarios
  many_to_one :administrador, :class=>Usuario, :key=>:administrador_grupo
end

class Grupo_Usuario < Sequel::Model
  many_to_one :usuario
  many_to_one :grupo
end


class Base_Bibliografica < Sequel::Model
  def self.nombre_a_id_h
    $db['SELECT * FROM bases_bibliograficas'].inject({}) {|ac,v|
      ac[ v[:nombre] ]= v[:id]; ac
    }
  end
  def self.id_a_nombre_h
    $db['SELECT * FROM bases_bibliograficas'].inject({}) {|ac,v|
      ac[ v[:id] ]= v[:nombre]; ac
    }
  end
end


