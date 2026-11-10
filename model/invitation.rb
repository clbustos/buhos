require 'securerandom'

class Invitation < Sequel::Model
  class InvalidRegistration < StandardError; end

  many_to_one :systematic_review
  many_to_one :sender, class: :User, key: :sender_id
  many_to_one :user

  def suggested_login
    base=name.downcase.gsub(/[[:space:]]+/, '').gsub(/[^[:alnum:]_.-]/, '')
    base='user' if base.empty?
    base=base[0, 240]
    candidate=base
    suffix=1
    while User.where(Sequel.function(:lower, :login)=>candidate).count > 0
      candidate="#{base}#{suffix}"
      suffix+=1
    end
    candidate
  end

  # A conditional update makes repeat submissions harmless and sends one notice.
  def decide!(value)
    raise ArgumentError unless %w[accepted rejected].include?(value)
    db.transaction do
      changed=self.class.where(id: id, decision: 'pending').update(decision: value)
      if changed == 1
        review=systematic_review
        administrator_id=review.sr_administrator || review.group&.group_administrator
        if administrator_id
          Message.create(user_from: sender_id, user_to: administrator_id,
                         subject: I18n.t('invitations.response_subject', review: review.name),
                         text: I18n.t("invitations.response_#{value}", name: name, email: email, review: review.name),
                         time: DateTime.now, viewed: false)
        end
      end
    end
    refresh
  end

  def register!(login, password, repeat_password)
    raise InvalidRegistration, 'invalid_login' unless login.match?(/\A[[:alnum:]_.-]{1,255}\z/)
    raise InvalidRegistration, 'password_required' if password.strip.empty?
    raise InvalidRegistration, 'password_mismatch' unless password == repeat_password
    db.transaction do
      refresh
      raise InvalidRegistration, 'unavailable' unless decision == 'accepted' && user_id.nil?
      raise InvalidRegistration, 'invalid_group' unless systematic_review.group
      raise InvalidRegistration, 'login_taken' if User.where(Sequel.function(:lower, :login)=>login.downcase).count > 0
      raise InvalidRegistration, 'email_exists' if User.where(Sequel.function(:lower, :email)=>email.downcase).count > 0
      account=User.create(name: name, email: email, login: login,
                          password: Digest::SHA1.hexdigest(password), role_id: 'analyst', active: true, language: language)
      claimed=self.class.where(id: id, decision: 'accepted', user_id: nil).update(user_id: account.id)
      raise InvalidRegistration, 'unavailable' unless claimed == 1
      GroupsUser.insert(group_id: systematic_review.group_id, user_id: account.id)
      SystematicReviewUserData.create(user_id: account.id, systematic_review_id: systematic_review_id,
                                     invitation_sent: email_sent)
      refresh
      account
    end
  rescue Sequel::UniqueConstraintViolation
    raise InvalidRegistration, 'login_taken'
  end
end
