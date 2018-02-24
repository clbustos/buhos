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

  def change_password(password)
    Usuario[self[:id]].update(:password=>Digest::SHA1.hexdigest(password))
  end



  def self.create_new_user(language='en')
    ultimo_usuario=$db["SELECT max(id) as max_id from usuarios"].get(:max_id).to_i
    n_id=ultimo_usuario+1
    Usuario.insert(:login=>"user_#{n_id}", :nombre=>I18n::t(:User_only_name, :user_name=>n_id), :password=>Digest::SHA256.hexdigest("user_#{n_id}") , :rol_id=>'analyst', :activa=>true,:language=>language)
  end
end