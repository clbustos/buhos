# Genera estadísticas para una
# revision sistematica en general
# y para cada uno de sus artículos

class AnalisisRevisionSistematica
  attr_reader :rs
  # Identificadores de los canonicos ingresados por registro
  attr_reader :cd_reg_id
  # Identificación de los canónicos ingresados por referencia
  attr_reader :cd_ref_id
  # Identificacion de todos los documentos canonicos
  attr_reader :cd_todos_id
  # Referencias entre canonicos
  attr_reader :rec
  # Hash de canonico, con citas recibidas
  attr_reader :ref_cuenta_entrada
  # Hash de canonico, con citas recibidas
  attr_reader :ref_cuenta_salida
  #
  # @param rs objeto Revision_Sistematica
  def initialize(rs)
    @rs=rs
    procesar_indicadores_basicos
    procesar_numero_citas
  end

  def cd_count_entrada(id)
    @ref_cuenta_entrada[id]
  end

  def cd_count_salida(id)
    @ref_cuenta_salida[id]
  end

  def cd_count_ref
    @cd_ref_id.length
  end

  def cd_count_reg
    @cd_reg_id.length
  end

  # Señala si un cd es parte de un registro,
  # es decir, si aparece en alguna de las busquedas
  def cd_en_registro?(id)
    @cd_reg_id.include? id
  end

  # Señala si un cd es parte de una referencia
  # Es decir, en algún momento fue citado por alguien.
  def cd_en_referencia?(id)
    @cd_ref_id.include? id
  end

  def cd_count_total
    @cd_todos_id.length
  end


  def procesar_indicadores_basicos
    @cd_reg_id=@rs.cd_registro_id
    @cd_ref_id=@rs.cd_referencia_id
    @cd_todos_id=(@cd_reg_id + @cd_ref_id).uniq
    @rec=@rs.referencias_entre_canonicos
  end

  def procesar_numero_citas
    @ref_cuenta_entrada=@rec.to_hash_groups(:cd_destino).inject({}) {|ac, v|
      ac[v[0]]=v[1].length; ac
    }
    @ref_cuenta_salida=@rec.to_hash_groups(:cd_origen).inject({}) {|ac, v|
      ac[v[0]]=v[1].length; ac
    }
  end


end