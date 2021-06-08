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

require_relative 'systematic_review_views_mixin.rb'
require_relative 'tag'
require_relative 'messages'
class SystematicReview < Sequel::Model
  include SystematicReviewViewsMixin
  one_to_many :searches
  one_to_many :message_srs, :class=>MessageSr

  one_to_many :t_classes, :class=>T_Class
  many_to_one :group







  def keywords_as_array
    keywords.nil? ? nil : keywords.split(";").map {|v| v.strip}
  end

  def current_stages
    stages=Buhos::Stages::IDS
    stages[0..stages.find_index(self.stage.to_sym)]
  end
  def group_name
    group.nil? ? "--#{::I18n::t(:group_not_assigned)}--" : group.name
  end

  def taxonomy_categories_id
    Systematic_Review_SRTC.where(:sr_id=>self[:id]).map(:srtc_id)
  end

#  def t_classes_documents
#    @t_classes_documents||=t_classes_dataset.where(:type=>"document")
#  end

  def statistics_tags(stage=nil, order="n_documents DESC ,p_yes DESC,text ASC")
    cd_query=1
    if stage
      cd_ids=cd_id_by_stage(stage)
      cd_query=" canonical_document_id IN (#{cd_ids.join(",")}) "
    end
    $db["SELECT t.*, CASE WHEN tecl.tag_id IS NOT NULL THEN 1 ELSE 0 END  as tag_en_clases FROM (SELECT `tags`.*, COUNT(DISTINCT(canonical_document_id)) as n_documents, 1.0*SUM(CASE WHEN decision='yes' THEN 1 ELSE 0 END)/COUNT(*) as p_yes FROM `tags` INNER JOIN `tag_in_cds` tec ON (tec.`tag_id` = `tags`.`id`)
WHERE tec.systematic_review_id=?
AND  #{cd_query} GROUP BY tags.id) as t LEFT JOIN tag_in_classes tecl ON t.id=tecl.tag_id GROUP BY t.id ORDER BY #{order}
 ", self.id]


  end


  def group_users
    group.nil? ? nil : group.users
  end
  def stage_name
    Buhos::Stages.get_stage_name(self.stage.to_sym)
  end
  def administrator_name
    self[:sr_administrator].nil? ? "-- #{I18n::t(:administrator_not_assigned)} --" : User[self[:sr_administrator]].name
  end

  def self.get_reviews_by_user(us_id)
    ids=$db["SELECT r.id FROM systematic_reviews r INNER JOIN groups_users gu on r.group_id=gu.group_id WHERE gu.user_id='#{us_id}'"].map{|v|v[:id]}
    SystematicReview.where(:id=>ids)
  end

  



  def cd_record_id
    Record.join(:records_searches, :record_id => :id).join(:searches, :id => :search_id).join(SystematicReview.where(:id => self[:id]), :id => :systematic_review_id).select_all(:canonical_documents).where(:valid=>true).group(:canonical_document_id).select_map(:canonical_document_id)
  end

  def cd_reference_id
    $db["SELECT canonical_document_id FROM searches b INNER JOIN records_searches br ON b.id=br.search_id INNER JOIN records_references rr ON br.record_id=rr.record_id INNER JOIN bib_references r ON rr.reference_id=r.id  WHERE b.systematic_review_id=? and r.canonical_document_id IS NOT NULL AND b.valid=1 GROUP BY r.canonical_document_id", self[:id]].select_map(:canonical_document_id)
  end





  def cd_all_id
    (cd_record_id + cd_reference_id).uniq
  end
  def cd_hash
    @cd_hash||=CanonicalDocument.where(:id=>cd_all_id).as_hash
  end

  # Presenta los documentos canonicos
  # para la revision. Une los por
  # registro y reference

  def canonical_documents(type=:all)
    cd_ids=case type
             when :record
               cd_record_id
             when :reference
               cd_reference_id
             when :all
                cd_all_id
             else
               raise(I18n::t(:Not_defined_for_this_stage))
           end
    if type==:all
      CanonicalDocument.join(cd_id_table, canonical_document_id: :id   )
    else
      CanonicalDocument.where(:id => cd_ids)
    end
  end
  # Canonical documents id with resolution for given stage
  def cd_id_resolutions(stage)
    Resolution.where(:systematic_review_id=>self[:id], :stage=>stage.to_s,:canonical_document_id=>cd_all_id,:resolution=>'yes').map(:canonical_document_id)
  end



  # Entrega la lista de canónicos documentos apropiados para cada stage
  def cd_id_by_stage(stage)
    case stage.to_s
      when 'search'
        cd_record_id # TODO: Check this
      when 'screening_title_abstract'
        cd_record_id
      when 'screening_references'
        count_references_rtr.where( Sequel.lit("n_references_rtr >= #{self[:n_min_rr_rtr]}") ).map(:cd_end)
        # Solo dejamos aquellos que tengan más de una references
      when 'review_full_text'
        rtr=resolutions_title_abstract.where(:resolution=>'yes', :canonical_document_id=>cd_record_id).select_map(:canonical_document_id)
        rr=resolutions_references.where(:resolution=>'yes', :canonical_document_id=>cd_reference_id-cd_record_id).select_map(:canonical_document_id)
        (rtr+rr).uniq
      when 'report'
        resolutions_full_text.where(:resolution=>'yes',:canonical_document_id=>cd_all_id).select_map(:canonical_document_id)
      else

        raise 'no definido'
    end
  end
  def fields
    SrField.where(:systematic_review_id=>self[:id]).order(:order)
  end
  def analysis_cd_tn
    "analysis_sr_#{self[:id]}"
  end
  # Entrega la tabla de text completo
  def analysis_cd
    table_name=analysis_cd_tn
    if !$db.table_exists?(table_name)
      SrField.update_table(self)
    end
    $db[table_name.to_sym]
  end

  def analysis_cd_user_row(cd,user)
    out=analysis_cd[:canonical_document_id=>cd[:id], :user_id=>user[:id]]
    if !out
      out_id=analysis_cd.insert(:canonical_document_id=>cd[:id], :user_id=>user[:id])
      out=analysis_cd[:id=>out_id]
    end
    out
  end


  def taxonomy_categories_hash
    $db["SELECT sr.name as sr_name, src.name as cat_name FROM sr_taxonomies sr INNER JOIN sr_taxonomy_categories src ON sr.id=src.srt_id INNER JOIN systematic_review_srtcs  srsrtcs ON srsrtcs.srtc_id=src.id WHERE srsrtcs.sr_id=? ORDER BY sr_name, cat_name",self[:id]].to_hash_groups(:sr_name)
  end
  def criteria_hash
    $db["SELECT criteria_type, c.id, c.text FROM  criteria c INNER JOIN sr_criteria sr ON c.id=sr.criterion_id WHERE sr.systematic_review_id=?", self[:id]].to_hash_groups(:criteria_type)
  end

  # Delete systematic review and all associated objects
  # TODO: Move association to pertinent model
  def delete
    $db.transaction do

      $db[analysis_cd_tn.to_sym].delete if $db.table_exists?(analysis_cd_tn.to_sym)

      searches_id=Search.where(systematic_review_id:self[:id]).map(:id)
      m_srs_id=$db[:message_srs].where(systematic_review_id:self[:id]).map(:id)

      $db[:records_searches].where(search_id: searches_id).delete
      $db[:message_sr_seens].where(m_rs_id: m_srs_id).delete

      $db[:tag_in_cds].where(systematic_review_id: self[:id]).delete
      $db[:tag_bw_cds].where(systematic_review_id: self[:id]).delete
      $db[:t_classes].where(systematic_review_id: self[:id]).delete
      $db[:systematic_review_srtcs].where(sr_id: self[:id]).delete
      $db[:sr_fields].where(systematic_review_id: self[:id]).delete
      $db[:sr_criteria].where(systematic_review_id: self[:id]).delete
      $db[:file_srs].where(systematic_review_id: self[:id]).delete
      $db[:decisions].where(systematic_review_id: self[:id]).delete
      $db[:resolutions].where(systematic_review_id: self[:id]).delete
      $db[:cd_criteria].where(systematic_review_id: self[:id]).delete
      $db[:allocation_cds].where(systematic_review_id: self[:id]).delete

      Search.where(systematic_review_id:self[:id]).delete
      $db[:message_srs].where(systematic_review_id:self[:id]).delete
      $db[:systematic_reviews].where(id:self[:id]).delete

    end
    true
  end

end
