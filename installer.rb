require 'sequel'
require 'haml'
require 'logger'
require 'i18n'
require 'dotenv'

#require 'i18n/backend/fallbacks'


Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end

module BibRevSys
  # This modular Sinatra app generates a simple form to install
  # BibSysRev
  class Installer < Sinatra::Base

    helpers Sinatra::Partials
    helpers Sinatra::Mobile
    helpers DOIHelpers
    helpers HTMLHelpers
    register Sinatra::I18n
    register Sinatra::Mensajes
    helpers do
      def permiso(p)
        true
      end
      def available_db_adapters
        ["mysql2","sqlite"]
      end

      def form_fields
        {
                      db_adapter:     {default:'mysql2'},
                      db_hostname:    {default: 'localhost'},
                      db_port:        {default: 3306},
                      db_username:    {default: 'bibsysrev'},
                      db_password:    {default: nil},
                      db_database:    {default: 'bibsysrev'},
                      db_filename:    {default: 'db.sqlite'},
                      proxy_hostname: {default:nil},
                      proxy_port:     {default:nil},
                      proxy_user:     {default:nil},
                      proxy_password: {default:nil},
                      scopus_key:     {default:nil}
        }
      end
      def optional_fields
        [:proxy_hostname, :proxy_port,:proxy_user, :proxy_password, :scopus_key]
      end
      def install_log(t)
        log=Logger.new('log/installer.log')
        log.info(t)
      end
    end


    set :session_secret, 'installer_secret'

    enable :logging, :dump_errors, :raise_errors, :sessions

    configure :development do |c|
      c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
    end

    configure :production do |c|
      c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
    end

# this is required if you want to assume the default path
    set :root, File.dirname(__FILE__)


    get '/' do
      redirect '/installer/select_language'
    end
    get '/installer/select_language' do

      haml "installer/select_language".to_sym, :layout=>"installer/layout".to_sym
    end



    post '/installer/select_language' do
      session['language']=params['language']
      ::I18n.locale=session['language']
      install_log("Language:#{session['language']}")
      redirect '/installer/basic_data_form'
    end

    get '/installer/basic_data_form' do
      @form_fields=form_fields
      @env_exists=File.exist?(".env")
      @env_text=File.read(".env") if @env_exists
      @available_db_adapters=available_db_adapters
      haml "installer/basic_data_form".to_sym, :layout=>"installer/layout".to_sym
    end
    post '/installer/basic_data_form' do
      ff=form_fields
      extra_env=[]
      ff.each_key {|key|
        if params[key.to_s].chomp==""
          session[key]=nil
        else
          session[key]=params[key.to_s]
          extra_env.push("#{key.to_s.upcase}=#{params[key.to_s]}") if optional_fields.include? key
        end
      }
      if params["db_adapter"]=='sqlite'
        connection_string=sprintf("DATABASE_URL=%s://%s", params['db_adapter'], params['db_filename'])
      else
        connection_string=sprintf("DATABASE_URL=%s://%s:%s@%s:%d/%s", params['db_adapter'],params['db_username'], params['db_password'], params['db_hostname'], params['db_port'], params['db_database'])
      end
      final_env=connection_string+("\n")+extra_env.join("\n")
      begin
        File.open(".env","w") {|file|
          file.puts final_env
        }
        # Only the user that runs the server have access to .env
        File.chmod(0700,".env")


        #begin
        Dotenv.load(".env")
      rescue Errno::EACCES
        halt(500,t("installer.no_env_file_access"))
      rescue StandardError
        halt(t("installer.cant_read_env_file"))
      end
      redirect '/installer/populate_database'
    end
    get '/installer/populate_database' do

      Dotenv.load(".env")
      @error_conexion=false
      begin
        db=Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8',:reconnect=>true)
      rescue Sequel::DatabaseConnectionError => e
        @error_conexion=e
      end
      haml "installer/populate_database".to_sym, :layout=>"installer/layout".to_sym
    end

    get '/installer/populate_database_2' do
      Dotenv.load(".env")

      log_db_install=Logger.new("log/installer_sql.log")
      db=Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8',:reconnect=>true)
      db.logger=log_db_install
      load("db/create_schema.rb")
      @pdb_stage="installer.population_begin"

      begin
        @pdb_stage="installer.schema_creation"

        BibRevSys::SchemaCreation.create_schema(db)

        @pdb_stage="installer.schema_migrations"
        Sequel.extension :migration

        Sequel::Migrator.run(db, "db/migrations")
        if db[:sr_taxonomies].count==0
          @pdb_stage="installer.basic_data"
          BibRevSys::SchemaCreation.create_bootstrap_data(db,session['language'])
        end
      rescue StandardError=>e
        @error=e
      end
      haml "installer/populate_database_2".to_sym, :layout=>nil
    end

    get '/installer/end_installation.rb' do
      begin
      File.open("config/installed","w") {|file| file.puts "Installed on #{DateTime.now()}"}
      rescue StandardError=>e
        @e=e
      end
      haml "installer/end_installation".to_sym, :layout=>"installer/layout".to_sym

    end
  end



end