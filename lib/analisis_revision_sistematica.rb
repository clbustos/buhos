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
  def cd_hash
    @cd_hash||=Canonico_Documento.where(:id=>@cd_todos_id).as_hash
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
  def mas_citados(n=20)
    @ref_cuenta_entrada.sort_by {|a| a[1]}.reverse[0...n]
  end
  def con_mas_referencias(n=20)
    @ref_cuenta_salida.sort_by {|a| a[1]}.reverse[0...n]
  end
  # Señala cuales son los jueces (personas de deben evaluar) y cuantos juicios tienen
  def decisiones_usuarios(etapa)
    @rs.grupo_usuarios.inject({}) {|ac,usuario|
      ac[usuario.id]={usuario: usuario, adu: AnalisisDecisionUsuario.new(@rs.id,usuario.id, etapa )}
      ac
    }
  end
  # Se analiza cada cd y se cuenta cuantas decisiones para cada tipo
  def decisiones_primera_etapa
    @decisiones_primera_etapa||=decisiones_primera_etapa_calculo
  end
  def decisiones_primera_etapa_calculo

    decisiones=Decision.where(:canonico_documento_id=>@cd_reg_id, :usuario_id=>@rs.grupo_usuarios.map {|u| u[:id]}, :etapa=>"revision_titulo_resumen").group_and_count(:canonico_documento_id, :decision)
    n_jueces=@rs.grupo_usuarios.count

    total_por_cd=@cd_reg_id.inject({}) {|ac,v|
      ac[v]=decisiones.find_all {|dec| dec[:canonico_documento_id]==v }.inject({}) {|ac1,v1|   ac1[v1[:decision]]=v1[:count]; ac1 }
      suma=ac[v].inject(0) {|ac1,v1| ac1+v1[1]}
      ac[v][nil]=n_jueces-suma
      ac
    }
    total_por_cd
  end

end