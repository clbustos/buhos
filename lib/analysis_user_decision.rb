# Information about decisions taken by an user, on a systematic review of a scecific stage

class AnalysisUserDecision
  # Raw dataset of Decision
  attr_reader :decisions
  # Decision for each assignment
  attr_reader :decision_por_cd
  # Number of document for each type of decision
  attr_reader :total_decisions
  # Raw dataset of AllocationCd
  attr_reader :asignaciones
  def initialize(rs_id,user_id,stage)
    @rs_id=rs_id
    @user_id=user_id
    @stage=stage.to_s
    @asignaciones=nil?
    procesar_cd_ids
    process_basic_indicators
    #procesar_numero_citas
  end
  def revision_sistematica
    @rs||=SystematicReview[@rs_id]
  end
  def canonical_documents
    CanonicalDocument.where(:id=>@cd_ids)
  end
  def have_allocations?
    !@asignaciones.empty?
  end
  def allocated_to_cd_id(cd_id)
    @cd_ids.include? cd_id.to_i
  end
  def decision_cd_id(cd_id)
    @decision_por_cd[cd_id]
  end
  # Define @cd_ids. Si no se han asignado, los toma todos
  # Si existen asignaciones, sólo se consideran estas
  def procesar_cd_ids
    cd_stage=revision_sistematica.cd_id_by_stage(@stage)
    @asignaciones=AllocationCd.where(:systematic_review_id=>@rs_id, :user_id=>@user_id, :canonical_document_id=>cd_stage, :stage=>@stage)
    if @asignaciones.empty?
      @cd_ids=[]
    else
      @cd_ids=@asignaciones.select_map(:canonical_document_id)
    end
  end
  def process_basic_indicators
    @decisions=Decision.where(:user_id => @user_id, :systematic_review_id => @rs_id,
                               :stage => @stage, :canonical_document_id=>@cd_ids).as_hash(:canonical_document_id)

    @decision_por_cd=@cd_ids.inject({}) {|ac, cd_id|
      dec_id=@decisions[cd_id]

      dec_dec=dec_id  ? dec_id[:decision] : Decision::NO_DECISION
      dec_dec=Decision::NO_DECISION if dec_dec.nil?
      ac[cd_id]=dec_dec
      ac
    }
    @total_decisions=@cd_ids.inject({}) {|ac,cd_id|
      dec=@decision_por_cd[cd_id]
      dec_i= dec.nil? ? Decision::NO_DECISION : dec
      ac[ dec_i]||=0
      ac[ dec_i]+=1
      ac
    }
  end

end