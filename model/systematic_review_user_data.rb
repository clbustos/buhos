class SystematicReviewUserData < Sequel::Model(:systematic_review_user_data)
  many_to_one :user
  many_to_one :systematic_review
end
