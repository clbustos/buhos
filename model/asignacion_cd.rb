require_relative 'revision_sistematica'
require_relative 'seguridad'
require_relative 'canonico_documento'


class Asignacion_Cd < Sequel::Model
  many_to_one :revision_sistematica, :class=>Revision_Sistematica
  many_to_one :usuario             , :class=>Usuario
  many_to_one :canonico_documento  , :class=>Canonico_Documento

  def self.update_assignation(rev_id, cds_id, user_id,stage, status=nil)
    current=Asignacion_Cd.where(:revision_sistematica_id=>rev_id, :usuario_id=>user_id, :etapa=>stage).map(:canonico_documento_id)

    to_remove=current-cds_id
    to_add=cds_id-current
    $db.transaction do
      Asignacion_Cd.where(:revision_sistematica_id=>rev_id, :usuario_id=>user_id, :etapa=>stage, :canonico_documento_id=>to_remove).delete
      to_add.each do |cd_id|
        Asignacion_Cd.insert(:revision_sistematica_id=>rev_id, :usuario_id=>user_id, :etapa=>stage, :canonico_documento_id=>cd_id, :estado=>status)
      end
    end
    user=Usuario[user_id]
    result=Result.new()
    result.success(I18n::t(:result_assignation_cd_to_user, :added=>to_add.length, :removed=>to_remove.length, :user_name=>user[:nombre]))
    result
  end


end