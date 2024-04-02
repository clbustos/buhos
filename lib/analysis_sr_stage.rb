# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
    assignations=AllocationCd.where(:systematic_review_id=>@sr.id, :stage=>@stage.to_s).group(:canonical_document_id, :user_id).map(:canonical_document_id).uniq
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
    n_jueces_por_cd=AllocationCd.where(:systematic_review_id=>@sr.id, :canonical_document_id=>cds, :stage=>@stage.to_s).group_and_count(:canonical_document_id).as_hash(:canonical_document_id)


#    n_jueces=@sr.group_users.count
    cds.inject({}) {|ac,v|
      ac[v]=empty_decisions_hash
      ac[v]=ac[v].merge decisions.find_all   {|dec|      dec[:canonical_document_id]==v }
                            .inject({}) {|ac1,v1|   ac1[v1[:decision]]=v1[:count]; ac1 }
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