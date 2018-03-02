module Sinatra
  module SessionAuth
    module Helpers
      def rol_usuario
        if(!session['user'].nil?)
          "guest"
        else
          session['role_id']
        end
      end
      def presentar_usuario
        ##$log.info(session)
        if(!session['user'].nil?)
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
            Authorization.insert(:id=>auth, :description=>::I18n::t("sinatra_auth.permission_created_by_administrator")) if Authorization[auth].nil?
            Role['administrator'].add_auth_to(Authorization[auth]) unless AuthorizationsRole[authorization_id:auth, role_id:'administrator']
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

      def is_session_user(user_id)
        user_id.to_i==session['user_id']
      end


      def review_belongs_to(revision_id,user_id)
        auth_to("review_admin") and SystematicReview[:id=>revision_id, :sr_administrator=>user_id]
      end

      def revision_analizada_por(revision_id,user_id)
        auth_to("review_analyze") and !$db["SELECT * FROM groups_users gu INNER JOIN systematic_reviews rs ON gu.group_id=rs.group_id WHERE rs.id=? AND gu.user_id=?", revision_id, user_id].empty?
      end

      def authorize(login, password)
        u=User.filter(:login=>login,:password=>Digest::SHA1.hexdigest(password))
        ##$log.info(u.first)
        if u.first
          user=u.first
          session['user']=user[:login]
          session['user_id']=user[:id]
          session['name']=user[:name]
          session['role_id']=user[:rol_id]
          session['authorizations']=user.authorizations.map {|v| v.id}
          session['language']=user.language
          true
        else
          false
        end
      end

      def desautorizar
        session.delete('user')
      end
    end
    def self.registered(app)
      app.helpers SessionAuth::Helpers

      app.before do
        if session['user'].nil?
          request.path_info='/login'
        end
      end


      app.get '/login' do
        haml :login
      end

      app.post '/login' do
        if(authorize(params['user'], params['password']))
          add_message ::I18n.t(:Successful_authentification)
          #log.info( ::I18n::t("sinatra_auth.sucessful_auth_for_user", user:params['user']))
          redirect(url("/"))
        else
          add_message ::I18n::t("sinatra_auth.error_on_auth"), :error
          redirect(url("/login"))
        end
      end


      app.get '/logout' do
        desautorizar
        redirect(url('/login'))
      end



    end
  end
  register SessionAuth
end