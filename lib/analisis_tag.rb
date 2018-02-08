
# Lo relacionado con analizar tags
module AnalisisTag
  def self.tag_en_cd_rs(revision,cd)
    AnalisisTag::Contenedor_Tags_En_Cd_Rs.new(revision,cd)
  end


  def self.tag_ref_cd_rs(revision,cd_start, cd_end)
    AnalisisTag::Contenedor_Tags_Ref_Cd_Rs.new(revision,cd_start, cd_end)
  end
end


require_relative 'analisis_tag/contenedor_tags_en_cd_rs'
require_relative 'analisis_tag/contenedor_tags_ref_cd_rs'
require_relative 'analisis_tag/tag_en_cd_rs'
require_relative 'analisis_tag/tag_ref_cd_rs'
