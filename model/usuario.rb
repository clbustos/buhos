class User < Sequel::Model

  def groups
    Group.where(:id=>GroupsUser.where(:user_id => self[:id]).map(:group_id))
  end

  def systematic_reviews_id

    $db["SELECT id FROM systematic_reviews rs INNER JOIN groups_users gu ON rs.group_id=gu.group_id WHERE user_id=?", self[:id]].select_map(:id)
  end

  def systematic_reviews
    SystematicReview.where(:id => systematic_reviews_id)
  end
  def accesible_users
    User.where(:id=>$db["SELECT DISTINCT(user_id) FROM groups_users WHERE group_id IN (SELECT group_id FROM groups_users WHERE user_id=?)", self[:id]].map(:user_id))
  end

  def change_password(password)
    User[self[:id]].update(:password=>Digest::SHA1.hexdigest(password))
  end



  def self.create_new_user(language='en')
    ultimo_usuario=$db["SELECT max(id) as max_id from users"].get(:max_id).to_i
    n_id=ultimo_usuario+1
    User.insert(:login=>"user_#{n_id}", :name=>I18n::t(:User_only_name, :user_name=>n_id), :password=>Digest::SHA256.hexdigest("user_#{n_id}") , :role_id=>'analyst', :active=>true,:language=>language)
  end
end