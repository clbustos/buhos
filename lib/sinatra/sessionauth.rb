# Copyright (c) 2016-2025, Claudio Bustos Navarrete
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
require 'securerandom'

module Sinatra
  module SessionAuth
    module Helpers
      REVIEW_MEMBER_PERMISSIONS = %w[review_view review_analyze canonical_document_view search_view
                                     record_view reference_view file_view tag_edit message_view].freeze
      REVIEW_OWNER_PERMISSIONS = %w[review_edit review_admin review_admin_view search_edit file_admin message_edit].freeze

      def independent_researcher?
        session['role_id'] == 'independent_researcher'
      end

      def scoped_researcher?
        independent_researcher? || session['role_id'] == 'review_collaborator'
      end

      def can_create_review?
        independent_researcher? || auth_to('review_edit')
      end

      def review_group_member?(review, user_id)
        review && GroupsUser.where(group_id: review.group_id, user_id: user_id).first
      end

      def scoped_review_owner?(review, user_id=session['user_id'])
        independent_researcher? && review && review.sr_administrator == user_id &&
          review_group_member?(review, user_id)
      end

      def research_review_scope
        path=Rack::Utils.unescape_path(request.path_info)
        case path
        when %r{\A/(?:review|(?:decision|resolution|canonical_documents)/review|tags/systematic_review|files/rs|allocation/user/\d+/review|tag/rename/review)/(\d+)(?:/|\z)}
          SystematicReview[Regexp.last_match(1)]
        when '/review/update', '/review/reassign_cd_to_user'
          scoped_review_from_id(params['review_id'])
        when '/review/files/add', '/review/search/uploaded_files/new', '/review/import_decisions_excel'
          scoped_review_from_id(params['systematic_review_id'])
        when '/search/update'
          if params['search_id'] == ''
            scoped_review_from_id(params['systematic_review_id'])
          elsif params['search_id'].to_s.match?(/\A\d+\z/)
            Search[params['search_id']]&.systematic_review
          end
        when '/searches/update_batch', '/review/criteria/cd'
          scoped_review_from_id(params['sr_id'])
        when %r{\A/review/edit_field/}
          field_id=params['pk'].to_s
          scoped_review_from_id(SrField[field_id]&.systematic_review_id) if field_id.match?(/\A\d+\z/)
        when %r{\A/canonical_document/user_allocation/}
          scoped_review_from_id(params['rs_id'])
        when '/file/unassign_sr'
          scoped_review_from_id(params['rs_id'])
        when %r{\A/search/(\d+)(?:/|\z)}
          Search[Regexp.last_match(1)]&.systematic_review
        when %r{\A/(?:file/|ViewerJS/\.\.file/)(\d+)/(?:download|view|page/)}
          file_id=Regexp.last_match(1)
          groups=GroupsUser.where(user_id: session['user_id']).select(:group_id)
          review_ids=FileSr.where(file_id: file_id).select(:systematic_review_id)
          SystematicReview.where(group_id: groups, id: review_ids).first
        end
      end

      def scoped_review_from_id(id)
        SystematicReview[id] if id.to_s.match?(/\A[1-9][0-9]*\z/)
      end

      def authorize_research_review_scope
        @permission_review=research_review_scope
        if @permission_review
          halt 403 unless review_group_member?(@permission_review, session['user_id'])
          check_research_review_resource
        elsif Rack::Utils.unescape_path(request.path_info).match?(%r{\A/review/\d+(?:/|\z)})
          halt 404
        end
      end

      def check_research_review_resource
        path=Rack::Utils.unescape_path(request.path_info)
        document_id=path[%r{/(?:canonical_document|cd)/(\d+)(?:/|\z)}, 1]
        document_id=params['cd_id'] if path.start_with?('/canonical_document/user_allocation/')
        if document_id
          halt 404 unless @permission_review.cd_all_id_table.where(cd_id: document_id).first
        end
        if path.match?(%r{\A/(?:decision/review|review/\d+/(?:extract_information|quality_assessment))/})
          user_id=path[%r{/user/(\d+)(?:/|\z)}, 1]
          halt 403 if user_id && !is_session_user(user_id)
        end
        if path.match?(%r{\A/(?:review/\d+/stage/[^/]+/(?:add_assign_user|rem_assign_user|reassign_user)|allocation/user)/(\d+)(?:/|\z)})
          halt 403 unless review_group_member?(@permission_review, Regexp.last_match(1))
        end
      end

      def allow_password_recovery?
        !Buhos::Configuration.smtp_settings[:server].to_s.strip.empty?
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
        elsif scoped_researcher? && @permission_review &&
              (REVIEW_MEMBER_PERMISSIONS.include?(auth) ||
               (REVIEW_OWNER_PERMISSIONS.include?(auth) && scoped_review_owner?(@permission_review)))
          true
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
        if scoped_researcher?
          review=@permission_review if @permission_review&.id.to_s == review_id.to_s
          return scoped_review_owner?(review || SystematicReview[review_id], user_id)
        end

        auth_to("review_admin") and SystematicReview[:id=>review_id, :sr_administrator=>user_id]
      end

      def review_analyzed_by(review_id, user_id)
        auth_to("review_analyze") and !$db["SELECT * FROM groups_users gu INNER JOIN systematic_reviews rs ON gu.group_id=rs.group_id WHERE rs.id=? AND gu.user_id=?", review_id, user_id].empty?
      end

      def authorize(login, password)
        u=User.filter(Sequel.lit("(login=? OR email=?) AND password=?", login,login, Digest::SHA1.hexdigest(password)))
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
                        /\A\/invitation\/[0-9a-f]{64}(?:\/(?:decision|register))?\z/,
                        /forgotten_password/,
                       /reset_link/,
                       /\A\/register\z/
        ]
        external_path_match= excluded_path.any? { |regex| request.path_info =~ regex }
        #$log.info(request.path_info=~external_path)
        #external_path=nil
        if session['user'].nil? and not external_path_match
          request.path_info='/login'
        elsif session['user'] && scoped_researcher?
          authorize_research_review_scope
        end
      end


      app.get '/login' do
        haml :login_2, :layout=>:layout_empty, :escape_html=>false
      end

      app.post '/login' do

        if !params['user'].nil? and !params['password'].nil? and  authorize(params['user'].strip, params['password'].strip)
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
        headers 'Cache-Control'=>'no-store', 'Referrer-Policy'=>'no-referrer'
        @t=params['t']
        if @t.is_a?(String) && !@t.empty?
          @user=User[token_password: @t]
          if @user && @user.token_datetime && (Time.now - @user.token_datetime)<60*30
            haml :reset_link, :layout=>:layout_empty, :escape_html=>false
          else
            redirect url("/login")  
          end
        else
          redirect url("/login")
        end

      end

      app.post '/reset_link' do
        token=params['t']
        @user=User[id: params['user_id']] if params['user_id'].to_s.match?(/\A[1-9][0-9]*\z/)
        eligible=User.where(id: @user&.id, token_password: token).
          where { token_datetime > Time.now - 30*60 }
        unless @user && token.is_a?(String) && !token.empty? && eligible.first
          add_message(::I18n::t("sinatra_auth.token_error"), :info)
          redirect url("/login")
        end

        password=params['password']
        if !password.is_a?(String) || password.strip.empty? || password != params['repeat_password']
          add_message(::I18n::t("password.not_equal_password"), :error)
          redirect url("/reset_link?t=#{Rack::Utils.escape(token)}")
        end
        if eligible.update(password: Digest::SHA1.hexdigest(password.strip), token_password: nil, token_datetime: nil) == 1
          SecurityEvent.add_user_event("password reset by reset link", request.ip, request.path_info,
                                       "password changed for user using reset link", @user.id)
          add_message(::I18n::t("sinatra_auth.password_update_relogin"))
        end
        redirect url("/login")
      end


      app.get '/forgotten_password' do
        haml :forgotten_password, :layout=>:layout_empty, :escape_html=>false
      end

      app.post '/forgotten_password' do
        email=params['email'].to_s.strip.downcase
        unless email.include?("@")
          add_message(::I18n::t("sinatra_auth.not_an_email"), :error)
          redirect url("/forgotten_password")
        end

        user=User.where(Sequel.function(:lower, :email)=>email).first
        if user
          previous_datetime=user.token_datetime
          if previous_datetime
            #prev_dat=Sequel.string_to_datetime(previous_datetime)
            if(Time.now - previous_datetime)<60
              add_message(::I18n::t("sinatra_auth.wait_for_next_reset"), :error)
              redirect url("/login")
            end
          end


          token=SecureRandom.hex(32)
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
