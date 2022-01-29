# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

# Provides information to user dashboard
class UserDashboardInfo
  attr_reader :user
  def initialize(user)
    @user=user
    @sr_active=user.systematic_reviews.where(:active=>true)
  end
  def unread_personal_messages
    Message.where(:user_to=>@user[:id]).exclude(:viewed=>true)
  end
  def unread_sr_messages(sr_id)
    ids=$db["SELECT mr.id FROM message_srs mr LEFT JOIN message_sr_seens mrv ON mr.id=mrv.m_rs_id WHERE mr.systematic_review_id=? AND ( user_id IS NULL OR (user_id=? AND viewed!=1))",sr_id, @user[:id]].map(:id)
    MessageSr.where(:id=>ids)
  end
  # Return the searches not ready for review
  def searches_not_ready(sr_id)
    Search.where(:user_id=>user[:id], :valid=>nil, :systematic_review_id=>sr_id)
  end
  def adu_for_sr(sr,stage)
    AnalysisUserDecision.new(sr[:id], @user[:id], stage)
  end
  # The user is the administrator of a specific systematic review
  def is_administrator_sr?(sr)
    user[:id]==sr[:sr_administrator]
  end

  def is_member?(sr)
    sr.group_users.nil? ? false : sr.group_users.include?(user)
  end
end