class Tag_En_Cd < Sequel::Model
  # Entrega los cds que corresponden a un determinado tag en una determinada revision sistematica
  def self.cds_rs_tag(revision,tag,solo_pos=false)
    sql_having=solo_pos ? " HAVING n_pos>0 ":""
    $db["SELECT cd.*,SUM(IF(decision='yes',1,0)) n_pos, SUM(IF(decision='no',1,0))  n_neg FROM tags_en_cds tcd INNER JOIN canonicos_documentos cd ON tcd.canonico_documento_id=cd.id WHERE tcd.tag_id=? AND tcd.revision_sistematica_id=? GROUP BY canonico_documento_id #{sql_having}", tag.id,revision.id]
    end
  def self.tags_rs_cd(revision,cd)
    Tag.inner_join(:tags_en_cds, :tag_id=>:id).where(:revision_sistematica_id=>revision.id, :canonico_documento_id=>cd.id)
  end

  def self.aprobar_tag(cd,rs,tag,usuario_id)
    raise ("Objetos erróneos") if cd.nil? or rs.nil? or tag.nil?
    tec_previo=Tag_En_Cd.where(:tag_id=>tag.id, :canonico_documento_id=>cd.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id)
    if tec_previo.empty?
      Tag_En_Cd.insert(:tag_id=>tag.id, :canonico_documento_id=>cd.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id,:decision=>"yes")
    else
      tec_previo.update(:decision=>"yes")

    end
  end
  def self.rechazar_tag(cd,rs,tag,usuario_id)
    raise ("Objetos erróneos") if cd.nil? or rs.nil? or tag.nil?
    tec_previo=Tag_En_Cd.where(:tag_id=>tag.id, :canonico_documento_id=>cd.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id)
    if tec_previo.empty?
      Tag_En_Cd.insert(:tag_id=>tag.id, :canonico_documento_id=>cd.id, :revision_sistematica_id=>rs.id, :usuario_id=>usuario_id,:decision=>"no")
    else
      tec_previo.update(:decision=>"no")
    end

  end
end
