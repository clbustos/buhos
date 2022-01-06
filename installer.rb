# encoding: UTF-8
#
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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


require 'sequel'
require 'haml'
require 'logger'
require 'i18n'
require 'dotenv'

#require 'i18n/backend/fallbacks'

require_relative 'lib/buhos'

Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end

module Buhos
  # This modular Sinatra app generates a simple form to install
  class Installer < Sinatra::Base

    helpers Sinatra::Partials
    helpers DOIHelpers
    helpers HTMLHelpers
    register Sinatra::I18n
    register Sinatra::Messages
    helpers do
      def auth_to(p)
        true
      end
      def base_dir
        File.expand_path(File.dirname(__FILE__))
      end

      def log_dir
        "log"
      end
      def env_file
        if ENV['RACK_ENV'].to_s == "test"
          ENV['DOT_ENV'] ? ENV['DOT_ENV'] : ".env.test"
        else
          ".env"
        end
      end
      def installed_file
        (ENV['RACK_ENV'].to_s == "test") ? "config/installed_test" : "config/installed"
      end

      def available_db_adapters
        ["sqlite","mysql2"]
      end

      def form_fields
        {
                      db_adapter:     {default:'sqlite'},
                      db_hostname:    {default: 'localhost'},
                      db_port:        {default: 3306},
                      db_username:    {default: 'buhos_user'},
                      db_password:    {default: 'password'},
                      db_database:    {default: 'buhos'},
                      db_filename:    {default: 'db.sqlite'},
                      proxy_hostname: {default:nil},
                      proxy_port:     {default:nil},
                      proxy_user:     {default:nil},
                      proxy_password: {default:nil},
                      scopus_key:     {default:nil},
                      ncbi_api_key:   {default:nil},
                      crossref_email: {default:nil}
        }
      end
      def optional_fields
        [:proxy_hostname, :proxy_port,:proxy_user, :proxy_password, :scopus_key,:ncbi_api_key,:crossref_email]
      end
    def install_log(t)
      Dir.mkdir log_dir unless File.exists? log_dir
        log=Logger.new("#{log_dir}/installer.log")
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
      @env_exists=File.exist?(env_file)
      @env_text=File.read(env_file) if @env_exists
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

        File.open(env_file,"w") {|file|
          file.puts final_env
        }
        # Only the user that runs the server have access to .env
        File.chmod(0700,env_file)

        #begin
        Dotenv.load(env_file)
      rescue Errno::EACCES
        halt(500,t("installer.no_env_file_access"))
      rescue StandardError
        halt(t("installer.cant_read_env_file"))
      end
      redirect '/installer/populate_database'
    end

    get '/installer/populate_database' do
      ENV['DATABASE_URL']=nil
      Dotenv.load(env_file)
      @error_conexion=false
      begin
        db=Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8',:reconnect=>true)
      rescue Sequel::DatabaseConnectionError => e
        @db_url=ENV['DATABASE_URL']
        @error_conexion=e
      end
      haml "installer/populate_database".to_sym, :layout=>"installer/layout".to_sym
    end

    get '/installer/populate_database_2' do
      Dotenv.load(env_file)

      log_db_install=Logger.new("#{log_dir}/installer_sql.log")
      db=Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8',:reconnect=>true)
      db.logger=log_db_install
      load("lib/buhos/create_schema.rb")
      @pdb_stage="installer.population_begin"

      begin
        @pdb_stage="installer.schema_creation"
        Buhos::SchemaCreation.create_schema(db)
        @pdb_stage="installer.schema_migrations"
        Sequel.extension :migration
        Sequel::Migrator.run(db, "db/migrations")
        @pdb_stage="installer.basic_data"
        Buhos::SchemaCreation.create_bootstrap_data(db,session['language'])

      rescue StandardError=>e
        @error=e
      end
      haml "installer/populate_database_2".to_sym, :layout=>nil
    end

    get '/installer/end_installation.rb' do
      begin
      File.open(installed_file,"w") {|file| file.puts "Installed on #{DateTime.now()}"}
      rescue StandardError=>e
        @e=e
      end
      haml "installer/end_installation".to_sym, :layout=>"installer/layout".to_sym

    end
  end



end
