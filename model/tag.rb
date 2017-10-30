class Tag < Sequel::Model
  def self.get_tag(nombre)
    tag=Tag.where(:texto=>nombre).first
    if tag.nil?
      tag_id=Tag.insert(:texto=>nombre)
      tag=Tag[tag_id]
    end
    tag
  end

end

class T_Clase < Sequel::Model
  def tags
    Tag.join(:tags_en_clases, tag_id: :id ).select_all(:tags).where(:tc_id=>self.id)
  end
  def asignar_tag(tag)
    tag_en_clase=Tag_En_Clase.where(:tag_id=>tag[:id],:tc_id=>self.id)
    if(tag_en_clase.empty?)
      Tag_En_Clase.insert(:tag_id=>tag[:id],:tc_id=>self.id)
    end

  end
end


class Tag_En_Clase < Sequel::Model

end

class Tag_En_Referencia_Entre_Cn  < Sequel::Model

end