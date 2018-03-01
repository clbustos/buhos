require_relative 'analysis_sr_stage'

# Provides methods for analysis of a stage on a systematic review
# Used by AnalysisSystematicReview
module AnalysisSrStageMixin
  def get_asrs(stage)
    Analysis_SR_Stage.new(@rs, stage)
  end
  # Se entrega un hash de cada cd con su resolucion
  def resolution_by_cd(etapa)
    @resolution_by_cd_h ||= {}
    @resolution_by_cd_h[etapa] ||= get_asrs(etapa).resolutions_by_cd
  end
  # Count how many DC belongs to each pattern
  def count_by_pattern(list)
    list.inject({}) {|ac, v|
      ac[v[1]] ||= 0
      ac[v[1]] += 1
      ac
    }
  end
  def resolution_pattern(stage)
    count_by_pattern(resolution_by_cd(stage))
  end
  # Se analiza cada cd y se cuenta cuantas decisiones para cada tipo
  def decisions_by_cd(etapa)

    @decisions_by_cd_h ||= {}
    @decisions_by_cd_h[etapa] ||= get_asrs(etapa).decisions_by_cd
  end

# Define cuantos CD están en cada patrón
  def decisions_pattern(etapa)
    count_by_pattern(decisions_by_cd(etapa))
  end

# provides a hash, with keys containing the users decisions and values
# with the pattern for resolutions
  def resolutions_f_pattern_decision(etapa)
    cds = @rs.cd_id_por_etapa(etapa)
    rpc = resolution_by_cd(etapa)
    dpc = decisions_by_cd(etapa)
    cds.inject({}) {|ac, cd_id|
      patron = dpc[cd_id]
      ac[patron] ||= {"yes" => 0, "no" => 0, Resolucion::NO_RESOLUCION => 0}
      ac[patron][rpc[cd_id]] += 1
      ac
    }
  end

  def cd_from_pattern(etapa, patron)

    decisions_by_cd(etapa).find_all {|v|
      v[1] == patron
    }.map {|v| v[0]}


  end

# Señala cuales son los jueces (personas de deben evaluar) y cuantos juicios tienen
  def user_decisions(etapa)
    @rs.grupo_usuarios.inject({}) {|ac, usuario|
      ac[usuario.id] = {usuario: usuario, adu: AnalysisUserDecision.new(@rs.id, usuario.id, etapa)}
      ac
    }
  end


  def cd_rejected_id(stage)
    get_asrs(stage).cd_rejected_id
  end

  def cd_accepted_id(stage)
    get_asrs(stage).cd_accepted_id
  end

  def cd_screened_id(stage)
    get_asrs(stage).cd_screened_id
  end

  def outgoing_citations(stage, cd_id)
    get_asrs(stage).outcoming_citations cd_id
  end

  def incoming_citations(stage, cd_id)
    get_asrs(stage).incoming_citations cd_id
  end

  def cd_id_assigned_by_user(stage, user_id)
    get_asrs(stage).cd_id_assigned_by_user(user_id)
  end

  def cd_without_allocations(stage)
    get_asrs(stage).cd_without_allocations
  end

  def cd_without_abstract(stage)
    get_asrs(stage).cd_without_abstract
  end

  def stage_complete?(stage)
    get_asrs(stage).stage_complete?
  end




end
