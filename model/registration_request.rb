require 'securerandom'

class RegistrationRequest < Sequel::Model
  class IdentityTaken < StandardError; end
  class AlreadyDecided < StandardError; end

  many_to_one :user

  def self.identity_taken?(login, email)
    User.where(Sequel.|({Sequel.function(:lower, :login)=>login},
                        {Sequel.function(:lower, :email)=>email})).first
  end

  def decide!(decision)
    options=db.database_type == :sqlite ? {mode: :immediate} : {}
    db.transaction(options) do
      current=self.class.where(id: id).for_update.first
      raise AlreadyDecided unless current.status == 'pending'

      account=nil
      if decision == 'approved'
        raise IdentityTaken if self.class.identity_taken?(login, email)

        account=User.create(name: name, login: login, email: email, language: language,
                            role_id: 'independent_researcher', active: true,
                            password: Digest::SHA1.hexdigest(SecureRandom.hex(32)),
                            token_password: SecureRandom.hex(32), token_datetime: Time.now)
      end
      update(status: decision, pending: nil, user_id: account&.id)
    end
    refresh
  end
end
