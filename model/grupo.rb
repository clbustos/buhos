require_relative 'usuario'
class Grupo < Sequel::Model
  class GroupHaveSystematicReviewsError < StandardError

  end
  many_to_many :usuarios
  many_to_one :administrador, :class => Usuario, :key => :administrador_grupo
  def revisiones_sistematicas
    Revision_Sistematica.where(:grupo_id=>self[:id])
  end
  def delete
    raise GroupHaveSystematicReviewsError unless revisiones_sistematicas.empty?
    Grupo_Usuario.where(:grupo_id=>self[:id]).delete
    super
  end
  def administrator_name
    administrador
    administrador.nil? ? I18n::t("error.group_without_administrator") : administrador.nombre
  end
end

