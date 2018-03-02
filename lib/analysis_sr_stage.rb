# Information about a systematic review on specific stage

class Analysis_SR_Stage
  attr_reader :sr
  attr_reader :stage
  def initialize(sr,stage)
    @sr=sr
    @stage=stage.to_sym
  end

  def incoming_citations(cd_id)
    cd_stage=@sr.cd_id_by_stage(@stage)
    rec=@sr.references_bw_canonical.where(:cd_end=>cd_id).map(:cd_start)
    rec & cd_stage
  end
  def outcoming_citations(cd_id)
    cd_stage=@sr.cd_id_by_stage(@stage)
    rec=@sr.references_bw_canonical.where(:cd_start=>cd_id).map(:cd_end)
    rec & cd_stage
  end
  def stage_complete?
    #$log.info(stage)
    if @stage==:search
      bds=@sr.searches_dataset
      bds.where(:valid=>nil).count==0 and bds.exclude(:valid=>nil).count>0

    elsif [:screening_title_abstract,:screening_references,:review_full_text].include? @stage
      res=resolutions_by_cd
      res.all? {|v| v[1]=='yes' or v[1]=='no'}
    else
      raise('Not defined yet')
    end
  end
  def cd_id_assigned_by_user(user_id)
    cds=@sr.cd_id_by_stage(@stage)
    (AllocationCd.where(:systematic_review_id=>@sr.id, :stage=>@stage.to_s, :user_id=>user_id).map(:canonical_document_id)) & cds
  end
  # Check what Canonical documents aren't assigned yet
  def cd_without_allocations
    cds=@sr.cd_id_by_stage(@stage)
    assignations=AllocationCd.where(:systematic_review_id=>@sr.id, :stage=>@stage.to_s).group(:canonical_document_id).map(:canonical_document_id)
    CanonicalDocument.where(:id=>cds-assignations)
  end

  def resolutions_by_cd
    cds=@sr.cd_id_by_stage(@stage)
    resolutions=Resolution.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :stage=>@stage.to_s).as_hash(:canonical_document_id)
    cds.inject({}) {|ac,v|
      val=resolutions[v].nil? ? Resolution::NO_RESOLUTION : resolutions[v][:resolution]
      ac[v]=val
      ac
    }
  end


  def empty_decisions_hash
    Decision::N_EST.keys.inject({}) {|ac,v|  ac[v]=0;ac }
  end

  def cd_screened_id
    cds=@sr.cd_id_by_stage(@stage)
    Decision.where(:canonical_document_id=>cds, :user_id=>@sr.group_users.map {|u| u[:id]}, :stage=>@stage.to_s).group(:canonical_document_id).map(:canonical_document_id)
  end

  def cd_rejected_id
    resolutions_by_cd.find_all {|v| v[1]=='no'}.map {|v| v[0]}
  end
  def cd_accepted_id
    resolutions_by_cd.find_all {|v| v[1]=='yes'}.map {|v| v[0]}
  end
  def decisions_by_cd
    cds=@sr.cd_id_by_stage(@stage)

    decisions=Decision.where(:canonical_document_id=>cds, :user_id=>@sr.group_users.map {|u| u[:id]}, :stage=>@stage.to_s).group_and_count(:canonical_document_id, :decision).all
    n_jueces=@sr.group_users.count
    cds.inject({}) {|ac,v|
      ac[v]=empty_decisions_hash
      ac[v]=ac[v].merge decisions.find_all   {|dec|      dec[:canonical_document_id]==v }
                            .inject({}) {|ac1,v1|   ac1[v1[:decision]]=v1[:count]; ac1 }
      suma=ac[v].inject(0) {|ac1,v1| ac1+v1[1]}
      ac[v][Decision::NO_DECISION]=n_jueces-suma
      ac
    }
  end

  def cd_without_abstract
    CanonicalDocument.where(id:@sr.cd_id_by_stage(@stage)).where(Sequel.lit("abstract IS NULL OR abstract=''"))
  end



end