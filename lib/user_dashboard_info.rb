# Provides information to user dashboard
class UserDashboardInfo
  attr_reader :user
  def initialize(user)
    @user=user
    @sr_active=user.systematic_reviews.where(:active=>true)
  end
  def unread_personal_messages
    Message.where(:user_to=>@user[:id]).exclude(:read=>true)
  end
  def unread_sr_messages(sr_id)
    ids=$db["SELECT mr.id FROM message_srs mr LEFT JOIN message_sr_seens mrv ON mr.id=mrv.m_rs_id WHERE mr.systematic_review_id=? AND ( user_id IS NULL OR (user_id=? AND read!=1))",sr_id, @user[:id]].map(:id)
    MessageSr.where(:id=>ids)
  end
  # Return the searches not ready for review
  def searches_not_ready(sr_id)
    Search.where(:user_id=>user[:id], :valid=>nil, :systematic_review_id=>sr_id)
  end
  def adu_for_sr(sr,stage)
    AnalysisUserDecision.new(sr[:id], @user[:id], stage)
  end
  def is_administrator_sr?(sr)
    user[:id]==sr[:sr_administrator]
  end

end