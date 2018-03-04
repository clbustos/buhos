class TagBwCd < Sequel::Model
  def self.tags_rs_cd(revision,cd_start, cd_end)
    Tag.inner_join(:tag_bw_cds, :tag_id=>:id).where(:systematic_review_id=>revision.id, :cd_start=>cd_start.id, :cd_end=>cd_end.id)
  end

  def self.approve_tag(cd_start,cd_end, rs,tag,user_id)
    raise ("Objetos erróneos") if cd_start.nil? or cd_end.nil? or rs.nil? or tag.nil?
    tec_previo=TagBwCd.where(:tag_id=>tag.id, :cd_start=>cd_start.id, :cd_end=>cd_end.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tec_previo.empty?
      TagBwCd.insert(:tag_id=>tag.id, :cd_start=>cd_start.id, :cd_end=>cd_end.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>"yes")
    else
      tec_previo.update(:decision=>"yes")
    end
  end
  def self.reject_tag(cd_start,cd_end,rs,tag,user_id)
    raise(I18n::t(:Strange_objects)) if cd_start.nil? or cd_end.nil? or rs.nil? or tag.nil?
    tec_previo=TagBwCd.where(:tag_id=>tag.id, :cd_start=>cd_start.id, :cd_end=>cd_end.id, :systematic_review_id=>rs.id, :user_id=>user_id)
    if tec_previo.empty?
      TagInCd.insert(:tag_id=>tag.id, :cd_start=>cd_start.id, :cd_end=>cd_end.id, :systematic_review_id=>rs.id, :user_id=>user_id,:decision=>"no")
    else
      tec_previo.update(:decision=>"no")
    end

  end



end