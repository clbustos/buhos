# Copyright (c) 2016-2018, Claudio Bustos Navarrete
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

require_relative 'sinatra/i18n'



module Buhos
  # @!group Error Codes
  class NoReviewIdError < StandardError

  end
  class NoUserIdError < StandardError

  end
  class NoCdIdError < StandardError

  end
  class NoSearchIdError < StandardError

  end
  class NoTagIdError < StandardError

  end
  class NoTagClassIdError < StandardError

  end

  class NoScopusMethodError < StandardError

  end
  class NoGroupIdError < StandardError
  end

  class NoRoleIdError < StandardError

  end

  class NoRecordIdError < StandardError

  end
  class NoFileIdError < StandardError

  end
  # @!endgroup
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

      app.error Buhos::NoGroupIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Group), code:env['sinatra.error'].message)
      end

      app.error Buhos::NoRoleIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Role), code:env['sinatra.error'].message)
      end

      app.error Buhos::NoSearchIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Search), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoCdIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Canonical_document), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoTagIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Tag), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoTagClassIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Tag_class), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoRecordIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:Record), code:env['sinatra.error'].message)
      end
      app.error Buhos::NoFileIdError do
        status 404
        ::I18n::t("error.no_code", object_name: ::I18n::t(:File), code:env['sinatra.error'].message)
      end
    end
  end
  register CustomErrors
end