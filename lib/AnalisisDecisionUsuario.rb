# Genera estadísticas para un conjunto de decisiones de un usuario

class AnalisisDecisionUsuario
  attr_reader :decisiones
  attr_reader :decision_por_cd
  attr_reader :total_decisiones
  attr_reader :asignaciones
  def initialize(rs_id,usuario_id,etapa)
    @rs_id=rs_id
    @usuario_id=usuario_id
    @etapa=etapa.to_s
    @asignaciones=nil?
    procesar_cd_ids
    procesar_indicadores_basicos
    #procesar_numero_citas
  end
  def revision_sistematica
    @rs||=Revision_Sistematica[@rs_id]
  end
  def canonicos_documentos
    Canonico_Documento.where(:id=>@cd_ids)
  end
  def tiene_asignaciones?
    !@asignaciones.empty?
  end
  # Define @cd_ids. Si no se han asignado, los toma todos
  # Si existen asignaciones, sólo se consideran estas
  def procesar_cd_ids
    cd_etapa=revision_sistematica.cd_id_por_etapa(@etapa)
    @asignaciones=Asignacion_Cd.where(:revision_sistematica_id=>@rs_id, :usuario_id=>@usuario_id, :canonico_documento_id=>cd_etapa, :etapa=>@etapa)
    if @asignaciones.empty?
      @cd_ids=[]
    else
      @cd_ids=@asignaciones.select_map(:canonico_documento_id)
    end
  end
  def procesar_indicadores_basicos
    @decisiones=Decision.where(:usuario_id => @usuario_id, :revision_sistematica_id => @rs_id,
                               :etapa => @etapa, :canonico_documento_id=>@cd_ids).as_hash(:canonico_documento_id)

    @decision_por_cd=@cd_ids.inject({}) {|ac, cd_id|
      dec_id=@decisiones[cd_id]

      dec_dec=dec_id  ? dec_id[:decision] : Decision::NO_DECISION
      dec_dec=Decision::NO_DECISION if dec_dec.nil?
      ac[cd_id]=dec_dec
      ac
    }
    @total_decisiones=@cd_ids.inject({}) {|ac,cd_id|
      dec=@decision_por_cd[cd_id]
      dec_i= dec.nil? ? Decision::NO_DECISION : dec
      ac[ dec_i]||=0
      ac[ dec_i]+=1
      ac
    }
  end

end