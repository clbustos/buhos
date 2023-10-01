# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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
#
module Sinatra
  module SessionAuth
    module Helpers
      def allow_password_recovery?
        !ENV['SMTP_SERVER'].nil?
      end
      def show_user
        ##$log.info(session)
        if !session['user'].nil?
          partial(:user)
        else
          partial(:guest)
        end
      end

      # Verifica que la persona tenga un authorization específico
      def auth_to(auth)

        #log.info(session['authorizations'])
        if session['user'].nil?
          false
        else
          if session['role_id']=='administrator'
            @admin_authorization_roles||=AuthorizationsRole.where(:role_id=>"administrator").select_map(:authorization_id)
            #@authorizations_cache||=Authorization.to_hash(:id)
            #Authorization.insert(:id=>auth, :description=>::I18n::t("sinatra_auth.permission_created_by_administrator")) if @authorizations_cache[auth].nil?
            unless @admin_authorization_roles.include? auth
              auth_o=Authorization[auth]
              raise Buhos::NoAuthorizationId, auth unless auth_o
              Role['administrator'].add_auth_to(auth_o)
            end
            true
          elsif session['authorizations'].include? auth
            true
          else
            false
          end
        end
      end

      def halt_unless_auth(*args)
        halt 403 if args.any? {|per| !auth_to(per)}
      end

      def halt_unless_auth_any(*args)
        halt 403 unless args.any? {|per| auth_to(per)}
      end

      def is_session_user(user_id)
        user_id.to_i==session['user_id']
      end


      def review_belongs_to(review_id,user_id)
        auth_to("review_admin") and SystematicReview[:id=>review_id, :sr_administrator=>user_id]
      end

      def review_analyzed_by(review_id, user_id)
        auth_to("review_analyze") and !$db["SELECT * FROM groups_users gu INNER JOIN systematic_reviews rs ON gu.group_id=rs.group_id WHERE rs.id=? AND gu.user_id=?", review_id, user_id].empty?
      end

      def authorize(login, password)
        u=User.filter(:login=>login,:password=>Digest::SHA1.hexdigest(password))
        ##$log.info(u.first)
        if u.first
          user=u.first
          session['user']=user[:login]
          session['user_id']=user[:id]
          session['name']=user[:name]
          session['role_id']=user[:role_id]
          session['authorizations']=user.authorizations.map {|v| v.id}
          session['language']=user.language

          ::I18n.locale = session['language'].to_sym

          true
        else
          false
        end
      end

      def logout
        session.delete('user')
      end
    end
    def self.registered(app)
      app.helpers SessionAuth::Helpers
      # todo: create a list of uri not evaluated for authentification
      app.before do
        excluded_path=[/file\/\d+\/download_external/,
                        /forgotten_password/,
                       /reset_link/
        ]
        external_path_match= excluded_path.any? { |regex| request.path_info =~ regex }
        #$log.info(request.path_info=~external_path)
        #external_path=nil
        if session['user'].nil? and not external_path_match
          request.path_info='/login'
        end
      end


      app.get '/login' do
        haml :login_2, :layout=>:layout_empty, :escape_html=>false
      end

      app.post '/login' do
        if authorize(params['user'].strip, params['password'].strip)
          add_message ::I18n.t(:Successful_authentification)
          #log.info( ::I18n::t("sinatra_auth.sucessful_auth_for_user", user:params['user']))
          redirect(url("/"))
        else
          add_message ::I18n::t("sinatra_auth.error_on_auth"), :error
          redirect(url("/login"))
        end
      end


      app.get '/logout' do
        logout
        redirect(url('/login'))
      end

      app.get '/reset_link' do
        @t=params['t']
        if @t
          @user=User[token_password: @t]
          if @user and (Time.now - @user.token_datetime)<60*30
            haml :reset_link, :layout=>:layout_empty, :escape_html=>false
          else
            redirect url("/login")  
          end
        else
          redirect url("/login")
        end

      end

      app.post '/reset_link' do

        @user=User[id: params['user_id']]
        raise Buhos::NoUserIdError, params['user_id'] unless @user
        if @user[:token_password]!=params['t']
          add_message(::I18n::t("sinatra_auth.token_error"), :info)
          SecurityEvent.add_user_event("token error for password reset",  request.ip,request.path_info,
                                       "password token", @user[:id] )
          redirect url("/login")
        else
          password_1=params['password']
          password_2=params['repeat_password']
          if password_1!=password_2
            add_message(::I18n::t("password.not_equal_password"), :error)
            redirect back
          else
            @user.update(token_password:nil,token_datetime: nil)
            @user.change_password(password_1)

            SecurityEvent.add_user_event("password reset by reset link",  request.ip,request.path_info,
                                         "password changed for user using reset link", @user[:id] )
            add_message(::I18n::t("sinatra_auth.password_update_relogin"))
            redirect url("/login")
          end

        end

      end


      app.get '/forgotten_password' do
        haml :forgotten_password, :layout=>:layout_empty, :escape_html=>false
      end

      app.post '/forgotten_password' do
        email=params['email']
        if not email.include? "@"
          add_message(::I18n::t("sinatra_auth.not_an_email"), :error)
          redirect url("/forgotten_password")
        end

        user=User.where(Sequel.lit('email=? and email IS NOT NULL', email)).first
        if user
          previous_datetime=user.token_datetime
          if previous_datetime
            #prev_dat=Sequel.string_to_datetime(previous_datetime)
            if(Time.now - previous_datetime)<60
              add_message(::I18n::t("sinatra_auth.wait_for_next_reset"), :error)
              redirect url("/login")
            end
          end


          token=Digest::SHA1.hexdigest(DateTime.to_s+user.password+user.name)
          user.update(token_password:token, token_datetime:DateTime.now)
          url="#{request.base_url}/reset_link?t=#{token}"
          subject=::I18n::t("sinatra_auth.password_reset_subject")
          message=::I18n::t("sinatra_auth.password_reset_message", url:url)
          oe=OutgoingEmail.new()
          oe.send_email(email,subject,message)

          SecurityEvent.add_user_event("forgotten_password",  request.ip,request.path_info,
                                       "password request for email #{email}", user[:id] )

        else
          SecurityEvent.add_nonuser_event("forgotten_password_bad_user",  request.ip,request.path_info,
                                       "password request for email #{email}", SecurityEvent::SECURITY_MEDIUM )
        end
        add_message(::I18n::t("sinatra_auth.if_email_exists_forgotten_sent"), :info)
        redirect url("/login")

      end



    end
  end
  register SessionAuth
end
