class Mensaje < Sequel::Model
  def usuario_nombre
    Usuario[self[:usuario_desde]].nombre
  end
  def respuestas
    Mensaje.where(:respuesta_a=>self[:id])
  end
end


class Mensaje_Rs < Sequel::Model
  def usuario_nombre
    Usuario[self[:usuario_desde]].nombre
  end
  # Mensajes que son respuesta a este mensaje
  def respuestas
    Mensaje_Rs.where(:respuesta_a=>self[:id])
  end

end

class Mensaje_Rs_Visto < Sequel::Model

end
