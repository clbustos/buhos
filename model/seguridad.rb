class AuthorizationsRole < Sequel::Model

end

class Role < Sequel::Model(:roles)

  many_to_many :authorizations, :join_table=>:authorizations_roles, :left_key=>:role_id, :right_key=>:authorization_id
  one_to_many :users
  def include_authorization?(auth)
    ##$log.info("POR BUSCAR:#{authorization}")
    ##$log.info(authorizations)
    authorizations.any? {|v|
    ##$log.info(v[:id]);
     v[:id]==auth}
  end

  def delete
    AuthorizationsRole.where(:rol_id=>self[:id]).delete
    super
  end

  def add_auth_to(auth)
    pr=AuthorizationsRole[role_id:self[:id], authorization_id:auth[:id]]
    AuthorizationsRole.insert(role_id:self[:id], authorization_id:auth[:id]) unless pr
  end

end


class Authorization < Sequel::Model
  many_to_many :roles, :join_table=>:authorization_roles, :left_key=>:authorization_id, :right_key=>:role_id
end


class User < Sequel::Model
  many_to_one :role

  def authorizations
    ##$log.info(self.rol)
    Role[self[:role_id]].authorizations
  end
end
