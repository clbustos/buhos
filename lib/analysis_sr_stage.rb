# Information about a systematic review on specific stage

class Analysis_SR_Stage
  attr_reader :sr
  attr_reader :stage
  def initialize(sr,stage)
    @sr=sr
    @stage=stage.to_sym
  end

  def incoming_citations(cd_id)
    cd_etapa=@sr.cd_id_por_etapa(@stage)
    rec=@sr.referencias_entre_canonicos.where(:cd_destino=>cd_id).map(:cd_origen)
    rec & cd_etapa
  end
  def outcoming_citations(cd_id)
    cd_etapa=@sr.cd_id_por_etapa(@stage)
    rec=@sr.referencias_entre_canonicos.where(:cd_origen=>cd_id).map(:cd_destino)
    rec & cd_etapa
  end
  def stage_complete?
    #$log.info(stage)
    if @stage==:busqueda
      bds=@sr.busquedas_dataset
      bds.where(:valid=>nil).count==0 and bds.exclude(:valid=>nil).count>0
    elsif [:revision_titulo_resumen,:revision_referencias,:revision_texto_completo].include? @stage
      res=resolutions_by_cd
      res.all? {|v| v[1]=='yes' or v[1]=='no'}
    else
      raise('Not defined yet')
    end
  end
  def cd_id_assigned_by_user(user_id)
    cds=@sr.cd_id_por_etapa(@stage)
    (Asignacion_Cd.where(:revision_sistematica_id=>@sr.id, :etapa=>@stage.to_s, :usuario_id=>user_id).map(:canonico_documento_id)) & cds
  end
  # Check what Canonical documents aren't assigned yet
  def cd_without_assignations
    cds=@sr.cd_id_por_etapa(@stage)
    assignations=Asignacion_Cd.where(:revision_sistematica_id=>@sr.id, :etapa=>@stage.to_s).group(:canonico_documento_id).map(:canonico_documento_id)
    Canonico_Documento.where(:id=>cds-assignations)
  end

  def resolutions_by_cd
    cds=@sr.cd_id_por_etapa(@stage)
    resoluciones=Resolucion.where(:revision_sistematica_id=>@sr.id, :canonico_documento_id=>cds, :etapa=>@stage.to_s).as_hash(:canonico_documento_id)
    cds.inject({}) {|ac,v|
      val=resoluciones[v].nil? ? Resolucion::NO_RESOLUCION : resoluciones[v][:resolucion]
      ac[v]=val
      ac
    }
  end


  def empty_decisions_hash
    Decision::N_EST.keys.inject({}) {|ac,v|  ac[v]=0;ac }
  end

  def cd_screened_id
    cds=@sr.cd_id_por_etapa(@stage)
    Decision.where(:canonico_documento_id=>cds, :usuario_id=>@sr.grupo_usuarios.map {|u| u[:id]}, :etapa=>@stage.to_s).group(:canonico_documento_id).map(:canonico_documento_id)
  end

  def cd_rejected_id
    resolutions_by_cd.find_all {|v| v[1]=='no'}.map {|v| v[0]}
  end
  def cd_accepted_id
    resolutions_by_cd.find_all {|v| v[1]=='yes'}.map {|v| v[0]}
  end
  def decisions_by_cd
    cds=@sr.cd_id_por_etapa(@stage)
    decisions=Decision.where(:canonico_documento_id=>cds, :usuario_id=>@sr.grupo_usuarios.map {|u| u[:id]}, :etapa=>@stage.to_s).group_and_count(:canonico_documento_id, :decision).all
    n_jueces=@sr.grupo_usuarios.count
    cds.inject({}) {|ac,v|
      ac[v]=empty_decisions_hash
      ac[v]=ac[v].merge decisions.find_all   {|dec|      dec[:canonico_documento_id]==v }
                            .inject({}) {|ac1,v1|   ac1[v1[:decision]]=v1[:count]; ac1 }
      suma=ac[v].inject(0) {|ac1,v1| ac1+v1[1]}
      ac[v][Decision::NO_DECISION]=n_jueces-suma
      ac
    }
  end

  def cd_without_abstract
    Canonico_Documento.where(id:@sr.cd_id_por_etapa(@stage)).where(Sequel.lit("abstract IS NULL OR abstract=''"))
  end



end