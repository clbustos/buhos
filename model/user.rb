# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

  def correct_password?(test_password)
    self.password == Digest::SHA1.hexdigest(test_password)
  end

  def self.create_new_user(language='en')
    ultimo_usuario=$db["SELECT max(id) as max_id from users"].get(:max_id).to_i
    n_id=ultimo_usuario+1
    User.insert(:login=>"user_#{n_id}", :name=>I18n::t(:User_only_name, :user_name=>n_id), :password=>Digest::SHA256.hexdigest("user_#{n_id}") , :role_id=>'analyst', :active=>true,:language=>language)
  end
end