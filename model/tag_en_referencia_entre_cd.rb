class Tag_En_Referencia_Entre_Cn  < Sequel::Model
  def self.tags_rs_cd(revision,cd_start, cd_end)
    Tag.inner_join(:tags_en_referencias_entre_cn, :tag_id=>:id).where(:revision_sistematica_id=>revision.id, :cd_origen=>cd_start.id, :cd_destino=>cd_end.id)
  end

  def self.aprobar_tag(cd_start,cd_end, rs,tag,usuario_id)
    raise ("Objetos erróneos") if cd_start.nil? or cd_end.nil? or rs.nil? or tag.nil?
    tec_previo=Tag_En_Referencia_Entre_Cn.where(:tag_id=>tag.id, :cd_origen=>cd_start.id, :cd_destino=>cd_end.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id)
    if tec_previo.empty?
      Tag_En_Referencia_Entre_Cn.insert(:tag_id=>tag.id, :cd_origen=>cd_start.id, :cd_destino=>cd_end.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id,:decision=>"yes")
    else
      tec_previo.update(:decision=>"yes")
    end
  end
  def self.rechazar_tag(cd_start,cd_end,rs,tag,usuario_id)
    raise(I18n::t(:Strange_objects)) if cd_start.nil? or cd_end.nil? or rs.nil? or tag.nil?
    tec_previo=Tag_En_Referencia_Entre_Cn.where(:tag_id=>tag.id, :cd_origen=>cd_start.id, :cd_destino=>cd_end.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id)
    if tec_previo.empty?
      Tag_En_Cd.insert(:tag_id=>tag.id, :cd_origen=>cd_start.id, :cd_destino=>cd_end.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id,:decision=>"no")
    else
      tec_previo.update(:decision=>"no")
    end

  end



end