class PermisosRol < Sequel::Model

end

class Rol < Sequel::Model(:roles)

  many_to_many :permisos, :join_table=>:permisos_roles, :left_key=>:rol_id, :right_key=>:permiso_id
  one_to_many :usuarios
  def incluye_permiso?(permiso)
    ##$log.info("POR BUSCAR:#{permiso}")
    ##$log.info(permisos)
    permisos.any? {|v|
    ##$log.info(v[:id]);
     v[:id]==permiso}
  end

  def delete
    PermisosRol.where(:rol_id=>self[:id]).delete
    super
  end

  def add_auth_to(auth)
    pr=PermisosRol[rol_id:self[:id], permiso_id:auth[:id]]
    PermisosRol.insert(rol_id:self[:id], permiso_id:auth[:id]) unless pr
  end

end


class Permiso < Sequel::Model
  many_to_many :roles, :join_table=>:permisos_roles, :left_key=>:permiso_id, :right_key=>:rol_id
end


class Usuario < Sequel::Model
  many_to_one :rol
  
  def permisos
    ##$log.info(self.rol)
    permisos=Rol[self.rol[:id]].permisos
  end
end
