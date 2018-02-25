require_relative 'sinatra/i18n'
module Buhos
  class NoReviewIdError < StandardError

  end
  class NoUserIdError < StandardError

  end

  class NoSearchIdError < StandardError

  end
end


module Sinatra
  module CustomErrors
    def self.registered(app)



      app.error Buhos::NoReviewIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Systematic_review), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoUserIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:User), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoSearchIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Search), code:env['sinatra.error'].message)
      end

    end
  end
  register CustomErrors
end