# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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

  # Entrega los cds que corresponden a un determinado tag en una determinada revision sistematica
  def self.cds_rs_tag(revision,tag,solo_pos=false,stage=nil)
    sql_lista_cd=""
    if stage
      sql_lista_cd=" AND cd.id IN (#{revision.cd_id_by_stage(stage).join(',')})"
    end
    sql_having=solo_pos ? " HAVING n_pos>0 ":""
    #$db["SELECT cd.*,SUM(IF(decision='yes',1,0)) n_pos, SUM(IF(decision='no',1,0))  n_neg FROM tag_in_cds tcd INNER JOIN canonical_documents cd ON tcd.canonical_document_id=cd.id WHERE tcd.tag_id=? AND tcd.systematic_review_id=? #{sql_lista_cd} GROUP BY canonical_document_id #{sql_having}", tag.id,revision.id]
    $db["SELECT cd.*,SUM(CASE WHEN decision='yes' then 1 ELSE 0 END) AS n_pos, SUM(CASE WHEN decision='no' THEN 1 ELSE 0 END) AS  n_neg FROM tag_in_cds tcd INNER JOIN canonical_documents cd ON tcd.canonical_document_id=cd.id WHERE tcd.tag_id=? AND tcd.systematic_review_id=? #{sql_lista_cd} GROUP BY canonical_document_id #{sql_having}", tag.id,revision.id]
  end

  # Entrega todos los tags que están en una determinada revisión y un determinado canónico
  def self.tags_rs_cd(revision,cd)
    Tag.inner_join(:tag_in_cds, :tag_id=>:id).where(:systematic_review_id=>revision.id, :canonical_document_id=>cd.id)
  end

  def self.approve_tag(cd,rs,tag,user_id)
    raise("Objetos erróneos") if cd.nil? or rs.nil? or tag.nil?
    tec_previo=TagInCd.where(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tec_previo.empty?
      TagInCd.insert(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>"yes")
    else
      tec_previo.update(:decision=>"yes")

    end
  end
  def self.reject_tag(cd,rs,tag,user_id)
    raise(I18n::t(:Strange_objects)) if cd.nil? or rs.nil? or tag.nil?
    tec_previo=TagInCd.where(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tec_previo.empty?
      TagInCd.insert(:tag_id=>tag.id, :canonical_document_id=>cd.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>"no")
    else
      tec_previo.update(:decision=>"no")
    end

  end
end
