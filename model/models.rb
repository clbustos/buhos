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

