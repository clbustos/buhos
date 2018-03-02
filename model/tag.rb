class Tag < Sequel::Model
  def self.get_tag(name)
    tag=Tag.where(:text=>name).first
    if tag.nil?
      tag_id=Tag.insert(:text=>name)
      tag=Tag[tag_id]
    end
    tag
  end

end

class T_Class < Sequel::Model
  def tags
    Tag.join(:tag_in_classes, tag_id: :id ).select_all(:tags).where(:tc_id=>self.id)
  end
  def asignar_tag(tag)
    tag_en_clase=TagInClass.where(:tag_id=>tag[:id],:tc_id=>self.id)
    if(tag_en_clase.empty?)
      TagInClass.insert(:tag_id=>tag[:id],:tc_id=>self.id)
    end

  end
end


class TagInClass < Sequel::Model

end

