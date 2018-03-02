require_relative 'usuario'
class Group < Sequel::Model
  class GroupHaveSystematicReviewsError < StandardError

  end
  many_to_many :users
  many_to_one :administrator, :class => User, :key => :group_administrator
  def systematic_reviews
    SystematicReview.where(:group_id=>self[:id])
  end
  def delete
    raise GroupHaveSystematicReviewsError unless systematic_reviews.empty?
    GroupsUser.where(:group_id=>self[:id]).delete
    super
  end
  def administrator_name

    administrator.nil? ? I18n::t("error.group_without_administrator") : administrator.name
  end
end

