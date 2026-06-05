# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

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
    elsif @stage==Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION
      cd_without_allocations_count==0
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
    CanonicalDocument.where(:id=>cd_without_allocations_id)
  end
  def cd_without_allocations_id
    cds=@sr.cd_id_by_stage(@stage)
    assignations=AllocationCd.where(:systematic_review_id=>@sr.id, :stage=>@stage.to_s).group(:canonical_document_id, :user_id).map(:canonical_document_id).uniq
    cds-assignations
  end
  def cd_without_allocations_count
    cd_without_allocations_id.length
  end

  def extract_information_stats
    raise('Not defined for this stage') unless @stage==Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION

    cds_id=@sr.cd_id_by_stage(@stage).map(&:to_i)
    fields=@sr.fields.map {|field| field[:name].to_sym}
    quality_criteria_ids=SrQualityCriterion.where(:systematic_review_id=>@sr[:id]).map(:quality_criterion_id)
    quality_active=quality_criteria_ids.any?

    form_information_by_pair={}
    if $db.table_exists?(@sr.analysis_cd_tn.to_sym)
      @sr.analysis_cd.where(:canonical_document_id=>cds_id).each do |row|
        has_form_information=fields.any? do |field|
          value=row[field]
          !value.nil? && value.to_s.strip!=''
        end
        form_information_by_pair[[row[:canonical_document_id].to_i, row[:user_id].to_i]]=true if has_form_information
      end
    end

    file_information_by_pair={}
    if defined?(FileExtractionInformation)
      FileExtractionInformation.where(:systematic_review_id=>@sr[:id], :canonical_document_id=>cds_id).each do |file_information|
        file_information_by_pair[[file_information[:canonical_document_id].to_i, file_information[:user_id].to_i]]=true
      end
    end

    quality_by_pair={}
    if quality_active
      CdQualityCriterion.
        where(:systematic_review_id=>@sr[:id], :canonical_document_id=>cds_id, :quality_criterion_id=>quality_criteria_ids).
        group_and_count(:canonical_document_id, :user_id).
        each do |row|
          quality_by_pair[[row[:canonical_document_id].to_i, row[:user_id].to_i]]=row[:count].to_i
        end
    end

    users=Array(@sr.group_users)
    users_by_id=users.each_with_object({}) {|user, memo| memo[user[:id].to_i]=user}
    assigned_pairs=AllocationCd.where(:systematic_review_id=>@sr[:id], :stage=>@stage.to_s, :canonical_document_id=>cds_id).all
    assigned_count_by_cd=assigned_pairs.each_with_object(Hash.new(0)) do |allocation, memo|
      memo[allocation[:canonical_document_id].to_i]+=1
    end

    user_statuses=users.each_with_object({}) do |user, memo|
      memo[user[:id].to_i]={user_id:user[:id].to_i, user:user, assigned_count:0, information_count:0, pending_information_count:0, quality_count:0, complete_count:0}
    end

    assigned_statuses=assigned_pairs.map do |allocation|
      cd_id=allocation[:canonical_document_id].to_i
      user_id=allocation[:user_id].to_i
      pair=[cd_id, user_id]
      has_information=form_information_by_pair[pair] || file_information_by_pair[pair]
      quality_count=quality_by_pair[pair].to_i
      has_quality=!quality_active || quality_count>=quality_criteria_ids.length
      complete=has_information && has_quality

      user_statuses[user_id]||={user_id:user_id, user:users_by_id[user_id] || User[user_id], assigned_count:0, information_count:0, pending_information_count:0, quality_count:0, complete_count:0}
      user_statuses[user_id][:assigned_count]+=1
      user_statuses[user_id][:information_count]+=1 if has_information
      user_statuses[user_id][:quality_count]+=1 if quality_active && has_quality
      user_statuses[user_id][:complete_count]+=1 if complete

      {
        canonical_document_id:cd_id,
        user_id:user_id,
        has_information:has_information,
        has_quality:has_quality,
        complete:complete
      }
    end

    document_statuses=cds_id.map do |cd_id|
      form_users=form_information_by_pair.keys.find_all {|pair| pair[0]==cd_id}.map {|pair| pair[1]}
      file_users=file_information_by_pair.keys.find_all {|pair| pair[0]==cd_id}.map {|pair| pair[1]}
      quality_users=quality_by_pair.find_all {|pair, count| pair[0]==cd_id && count.to_i>=quality_criteria_ids.length}.map {|pair, _count| pair[1]}
      has_information=(form_users | file_users).any?
      has_quality=!quality_active || quality_users.any?
      {
        canonical_document_id:cd_id,
        has_form_information:form_users.any?,
        has_file_information:file_users.any?,
        has_information:has_information,
        has_quality:has_quality,
        complete:has_information && has_quality,
        assigned_count:assigned_count_by_cd[cd_id]
      }
    end

    documents_complete=document_statuses.all? {|status| status[:complete]}
    assigned_complete=assigned_statuses.all? {|status| status[:complete]}
    stage_complete=cds_id.any? && cd_without_allocations_id.empty? && documents_complete && assigned_complete
    documents_with_information=document_statuses.count {|status| status[:has_information]}
    user_statuses.each_value do |status|
      status[:pending_information_count]=status[:assigned_count]-status[:information_count]
    end

    {
      quality_active:quality_active,
      quality_criteria_count:quality_criteria_ids.length,
      total_documents:cds_id.length,
      documents_with_information:documents_with_information,
      documents_pending_information:cds_id.length-documents_with_information,
      documents_with_quality:document_statuses.count {|status| status[:has_quality]},
      complete_documents:document_statuses.count {|status| status[:complete]},
      assigned_total:assigned_statuses.length,
      assigned_complete:assigned_statuses.count {|status| status[:complete]},
      stage_complete:stage_complete,
      user_statuses:user_statuses.values,
      document_statuses:document_statuses
    }
  end

  def no_resolution_count
    cds=@sr.cd_id_by_stage(@stage)
    return 0 if cds.empty?

    resolved=Resolution.where(:systematic_review_id=>@sr.id,
                              :canonical_document_id=>cds,
                              :stage=>@stage.to_s,
                              :resolution=>[Resolution::RESOLUTION_ACCEPT, Resolution::RESOLUTION_REJECT]).count
    cds.length-resolved
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
  def resolution_pattern
    resolutions_by_cd.inject({}) {|ac, v|
      ac[v[1]] ||= 0
      ac[v[1]] += 1
      ac
    }
  end

  def resolutions_commentary_by_cd
    cds=@sr.cd_id_by_stage(@stage)
    resolutions=Resolution.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :stage=>@stage.to_s).as_hash(:canonical_document_id)
    cds.inject({}) {|ac,v|
      val=resolutions[v].nil? ? nil : resolutions[v][:commentary]
      ac[v]=val
      ac
    }
  end

  def empty_decisions_hash
    Decision::N_EST.keys.inject({}) {|ac,v|  ac[v]=0;ac }
  end

  # Canonical document id for document screened on certain stage
  # it should be noted that documents could be partially screened, not necessarily  resolved
  def cd_screened_id
    cds=@sr.cd_id_by_stage(@stage)
    Decision.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :user_id=>@sr.group_users.map {|u| u[:id]}, :stage=>@stage.to_s).group(:canonical_document_id).map(:canonical_document_id)
  end

  def cd_resolved_id
    resolutions_by_cd.find_all {|v| (v[1]=='no' or v[1]=='yes')}.map {|v| v[0]}
  end
  def cd_rejected_id
    resolutions_by_cd.find_all {|v| v[1]=='no'}.map {|v| v[0]}
  end
  def cd_accepted_id
    resolutions_by_cd.find_all {|v| v[1]=='yes'}.map {|v| v[0]}
  end
  # Number of decisions by cd
  def decisions_by_cd
    cds=@sr.cd_id_by_stage(@stage)

    decisions=Decision.where(:systematic_review_id=>@sr.id,
                             :canonical_document_id=>cds,
                             :user_id=>@sr.group_users.map {|u| u[:id]},
                             :stage=>@stage.to_s).group_and_count(:canonical_document_id, :decision).all
    decisions_by_canonical_document=decisions.inject({}) do |ac, decision_count|
      cd_id=decision_count[:canonical_document_id]
      ac[cd_id] ||= {}
      ac[cd_id][decision_count[:decision]]=decision_count[:count]
      ac
    end
    n_jueces_por_cd=AllocationCd.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :stage=>@stage.to_s).group_and_count(:canonical_document_id).as_hash(:canonical_document_id)


#    n_jueces=@sr.group_users.count
    cds.inject({}) {|ac,v|
      ac[v]=empty_decisions_hash.merge(decisions_by_canonical_document[v] || {})
      suma=ac[v].inject(0) {|ac1,v1| ac1+v1[1]}
      n_jueces=n_jueces_por_cd[v].nil? ? 0 : n_jueces_por_cd[v][:count]
      ac[v][Decision::NO_DECISION]=n_jueces-suma
      ac
    }
  end


  def cd_without_abstract
    CanonicalDocument.where(id:@sr.cd_id_by_stage(@stage)).where(Sequel.lit("abstract IS NULL OR abstract=''"))
  end
end
