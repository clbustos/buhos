class Usuario < Sequel::Model
  def grupos
    Grupo.where(:id=>Grupo_Usuario.where(:usuario_id => self[:id]).map(:grupo_id))
  end

  def revisiones_sistematicas_id
    $db["SELECT id FROM revisiones_sistematicas rs INNER JOIN grupos_usuarios gu ON rs.grupo_id=gu.grupo_id WHERE usuario_id=?", self[:id]].select_map(:id)
  end

  def revisiones_sistematicas
    Revision_Sistematica.where(:id => revisiones_sistematicas_id)
  end
  def accesible_users

    Usuario.where(:id=>$db["SELECT DISTINCT(usuario_id) FROM grupos_usuarios WHERE grupo_id IN (SELECT grupo_id FROM grupos_usuarios WHERE usuario_id=?)", self[:id]].map(:usuario_id))
  end
end