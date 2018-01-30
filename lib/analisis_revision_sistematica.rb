# Genera estadísticas para una
# revision sistematica en general
# y para cada uno de sus artículos

class AnalisisRevisionSistematica
  # Object Systematic_Review
  attr_reader :rs
  # Id for canonical documents associated to records
  attr_reader :cd_reg_id
  # Id for canonical documents associated to references
  attr_reader :cd_ref_id
  # Id for all canonical documents
  attr_reader :cd_todos_id
  # References between canonical documents
  attr_reader :rec
  # Hash for canonical documents, with incoming citations
  attr_reader :ref_cuenta_entrada
  # Hash for canonical documents, with out citations
  attr_reader :ref_cuenta_salida
  #
  # @param rs object Systematic_Review
  def initialize(rs)
    @rs=rs
    procesar_indicadores_basicos
    procesar_numero_citas
    procesar_resoluciones
  end
  def cd_hash
    @rs.cd_hash
  end
  def cd_count_entrada(id)
    @ref_cuenta_entrada[id]
  end

  def cd_count_entrada_rtr(id)
    @cd_referencia_rtr[id]
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
  def cd_en_resolucion_etapa?(id,etapa)
    @cd_resoluciones[etapa.to_sym][id].nil? ? false : @cd_resoluciones[etapa.to_sym][id][:resolucion]=='yes'
  end
  # Señala si un cd es parte de una referencia
  # Es decir, en algún momento fue citado por alguien.
  def cd_en_referencia?(id)
    @cd_ref_id.include? id
  end

  def cd_count_total
    @cd_todos_id.length
  end

  def stage_complete?(stage)
    if stage==:busqueda
      bds=@rs.busquedas_dataset
      bds.where(:valid=>nil).count==0 and bds.exclude(:valid=>nil).count>0
    else
      raise('Not defined yet')
    end
  end

  def procesar_indicadores_basicos
    @cd_reg_id=@rs.cd_registro_id
    @cd_ref_id=@rs.cd_referencia_id
    @cd_todos_id=@rs.cd_todos_id
    @rec=@rs.referencias_entre_canonicos
  end
  private :procesar_indicadores_basicos
  def procesar_numero_citas
    @ref_cuenta_entrada=@rec.to_hash_groups(:cd_destino).inject({}) {|ac, v|
      ac[v[0]]=v[1].length; ac
    }
    @ref_cuenta_salida=@rec.to_hash_groups(:cd_origen).inject({}) {|ac, v|
      ac[v[0]]=v[1].length; ac
    }


    #cd[:n_referencias_rtr]


    @cd_referencia_rtr = @rs.cuenta_referencias_rtr.inject({}){|ac,v|
      ac[v[:cd_destino]]=v[:n_referencias_rtr];ac
    }


  end

  private :procesar_numero_citas
  def procesar_resoluciones
    @cd_resoluciones=Revision_Sistematica::ETAPAS.inject({}) do |ac,etapa|
      ac[etapa]=Resolucion.where(:revision_sistematica_id=>@rs.id, :etapa=>etapa.to_s).as_hash(:canonico_documento_id)
      ac
    end
  end

  private :procesar_resoluciones


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
  def decisiones_por_cd(etapa)
    @decisiones_por_cd_h||={}
    @decisiones_por_cd_h[etapa]||=decisiones_por_cd_calculo(etapa)
  end
  # Se entrega un hash de cada cd con su resolucion
  def resolucion_por_cd(etapa)
    @resolucion_por_cd_h||={}
    @resolucion_por_cd_h[etapa]||=resolucion_por_cd_calculo(etapa)
  end

  def cd_desde_patron(etapa,patron)
    decisiones_por_cd(etapa).find_all  {|v|
      v[1]==patron
    }.map {|v| v[0]}


  end
  # provides a hash, with keys containing the users decisions and values
  # with the pattern for resolutions
  def resoluciones_desde_patron_decision(etapa)
    cds=@rs.cd_id_por_etapa(etapa)
    rpc=resolucion_por_cd(etapa)
    dpc=decisiones_por_cd(etapa)
    cds.inject({}) {|ac,cd_id|
      patron=dpc[cd_id]
      ac[patron]||={"yes"=>0,"no"=>0, Resolucion::NO_RESOLUCION=>0}
      ac[patron][rpc[cd_id]]+=1
      ac
    }
  end
  # Define cuantos CD están en cada patrón
  def decisiones_patron(etapa)
    dpe=decisiones_por_cd(etapa)
    dpe.inject({}) {|ac,v|

      ac[ v[1]] ||=0
      ac[ v[1]] +=1
      ac
    }
  end

  def resolution_pattern(stage)
    rbd=resolucion_por_cd(stage)
    rbd.inject({}) {|ac,v|

      ac[ v[1]] ||=0
      ac[ v[1]] +=1
      ac
    }
  end

  def suma_decisiones_vacia
    Decision::N_EST.keys.inject({}) {|ac,v|  ac[v]=0;ac }
  end
  def decisiones_por_cd_calculo(etapa)
    cds=@rs.cd_id_por_etapa(etapa)
    decisiones=Decision.where(:canonico_documento_id=>cds, :usuario_id=>@rs.grupo_usuarios.map {|u| u[:id]}, :etapa=>etapa).group_and_count(:canonico_documento_id, :decision).all
    n_jueces=@rs.grupo_usuarios.count
    cds.inject({}) {|ac,v|
        ac[v]=suma_decisiones_vacia
        ac[v]=ac[v].merge decisiones.find_all   {|dec|      dec[:canonico_documento_id]==v }
                        .inject({}) {|ac1,v1|   ac1[v1[:decision]]=v1[:count]; ac1 }
        suma=ac[v].inject(0) {|ac1,v1| ac1+v1[1]}
        ac[v][Decision::NO_DECISION]=n_jueces-suma
        ac
    }
  end
  private :decisiones_por_cd_calculo

  def resolucion_por_cd_calculo(etapa)
    cds=@rs.cd_id_por_etapa(etapa)
    resoluciones=Resolucion.where(:revision_sistematica_id=>@rs.id, :canonico_documento_id=>cds, :etapa=>etapa).as_hash(:canonico_documento_id)
    #$log.info(resoluciones)
    #$log.info(resoluciones)
    cds.inject({}) {|ac,v|
      val=resoluciones[v].nil? ? Resolucion::NO_RESOLUCION : resoluciones[v][:resolucion]
      ac[v]=val
      ac
    }
  end

  private :resolucion_por_cd_calculo

  def patron_orden(a)
    - (1000*a["yes"].to_i + 100*a["no"].to_i + 10*a["undecided"].to_i + 1*a["ND"].to_i)
  end
  def patron_nombre(a)
    Decision::N_EST.map {|key,nombre|
      "#{nombre}:#{a[key]}"
    }.join(";")
  end
  def patron_id(a)
    Decision::N_EST.keys.map {|key|
      "#{key}_#{a[key]}"
    }.join("__")
  end

  def patron_desde_s(texto)
    texto.split("__").inject({}){|ac,v|
      key,value=v.split("_")
      ac[key]=value.to_i
      ac
    }
  end


end
