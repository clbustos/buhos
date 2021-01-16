# Copyright (c) 2016-2021, Claudio Bustos Navarrete
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


class TagInCd < Sequel::Model
  DECISION_YES="yes"
  DECISION_NO="no"
  # Retrievs the CD which uses a specific tag on a specific systematic review
  # @param systematic_review [SystematicReview]
  # @param tag [Tag]
  # @param only_pos Just show tags with positive decisions
  # @param stage name of stage, if a specific stage tags are needed
  def self.cds_rs_tag(systematic_review,tag,only_pos=false,stage=nil)
    sql_lista_cd=""
    if stage
      sql_lista_cd=" AND cd.id IN (#{systematic_review.cd_id_by_stage(stage).join(',')})"
    end
    sql_having=only_pos ? " HAVING n_pos>0 ":""
    #$db["SELECT cd.*,SUM(IF(decision='yes',1,0)) n_pos, SUM(IF(decision='no',1,0))  n_neg FROM tag_in_cds tcd INNER JOIN canonical_documents cd ON tcd.canonical_document_id=cd.id WHERE tcd.tag_id=? AND tcd.systematic_review_id=? #{sql_lista_cd} GROUP BY canonical_document_id #{sql_having}", tag.id,systematic_review.id]
    $db["SELECT cd.*,SUM(CASE WHEN decision='yes' then 1 ELSE 0 END) AS n_pos, SUM(CASE WHEN decision='no' THEN 1 ELSE 0 END) AS  n_neg FROM tag_in_cds tcd INNER JOIN canonical_documents cd ON tcd.canonical_document_id=cd.id WHERE tcd.tag_id=? AND tcd.systematic_review_id=? #{sql_lista_cd} GROUP BY canonical_document_id #{sql_having}", tag.id,systematic_review.id]
  end

  # All the tags on a specific systematic review and canonical document
  def self.tags_rs_cd(sr,cd)
    Tag.inner_join(:tag_in_cds, :tag_id=>:id).where(:systematic_review_id=>sr.id, :canonical_document_id=>cd.id)
  end

  # All the tags on a specific systematic review
  def self.tags_rs(systematic_review)
    Tag.inner_join(:tag_in_cds, :tag_id=>:id).where(:systematic_review_id=>systematic_review.id)
  end
  def self.approve_tag_batch(cd_a,rs,tag,user_id)
    result=Result.new
    $db.transaction do
      cd_a.each do |cd|
        TagInCd.approve_tag(cd,rs,tag,user_id)
      end
      result.success(I18n::t(:Tag_assigned_to_canonical_documents, tag_text:tag.text, cd_ids:cd_a.map(&:id)))
    end
    result
  end


  def self.reject_tag_batch(cd_a,rs,tag,user_id)
    result=Result.new
    $db.transaction do
      cd_a.each do |cd|
        TagInCd.reject_tag(cd,rs,tag,user_id)
      end
      result.success(I18n::t(:Tag_removed_to_canonical_documents, tag_text:tag.text, cd_ids:cd_a.map(&:id)))
    end
    result
  end

  def self.approve_tag(cd,rs,tag,user_id)
    raise(I18n::t(:Object_error)) if cd.nil? or rs.nil? or tag.nil?
    tag_in_cd_previous=TagInCd.where(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tag_in_cd_previous.empty?
      TagInCd.insert(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>DECISION_YES)
    else
      tag_in_cd_previous.update(:decision=>DECISION_YES)
    end
  end
  def self.reject_tag(cd,rs,tag,user_id)
    raise(I18n::t(:Object_error)) if cd.nil? or rs.nil? or tag.nil?
    tec_previo=TagInCd.where(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tec_previo.empty?
      TagInCd.insert(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>DECISION_NO)
    else
      tec_previo.update(:decision=>DECISION_NO)
    end

  end
end
