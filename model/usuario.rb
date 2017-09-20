class Usuario < Sequel::Model
  def grupos
    Grupo_Usuario.where(:usuario_id => self[:id])
  end


  def revisiones_sistematicas_id
    $db["SELECT id FROM revisiones_sistematicas rs INNER JOIN grupos_usuarios gu ON rs.grupo_id=gu.grupo_id WHERE usuario_id=?", self[:id]].select_map(:id)
  end

  def revisiones_sistematicas
    Revision_Sistematica.where(:id => revisiones_sistematicas_id)
  end
end