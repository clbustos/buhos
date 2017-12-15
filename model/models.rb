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



class Grupo_Usuario < Sequel::Model
  many_to_one :usuario
  many_to_one :grupo
end


class Referencia_Registro < Sequel::Model

end

class Base_Bibliografica < Sequel::Model
  def self.nombre_a_id_h
    $db['SELECT * FROM bases_bibliograficas'].as_hash(:nombre, :id)
  end
  def self.id_a_nombre_h
    $db['SELECT * FROM bases_bibliograficas'].as_hash(:id, :nombre)
  end
end

