# encoding: UTF-8

require "bundler/setup"
if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	# Windows doesn't have proper management of certificates for SSL. 
	# So, we have to user 'certified' gem to fix it
	require 'certified'
end


require 'sinatra'

# Vamos a activar el reloader en todos los casos
# Como el sistema está en vivo, es más peligroso hacer lo otro
require 'haml'
require 'logger'
require 'i18n'
require 'dotenv'

#require 'i18n/backend/fallbacks'


Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end

$test_mode=ENV['RACK_ENV'].to_s == "test"

installed_file= $test_mode ? "config/installed_test" : "config/installed"



if ENV['TEST_INSTALLER'] or !File.exist?(installed_file)
  load('installer.rb')
  Buhos::Installer.run!
  exit 1
end


if !$test_mode
  Dotenv.load("./.env")
end



set :session_secret, 'super secret2'

enable :logging, :dump_errors, :raise_errors, :sessions

configure :development do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
  set :show_exceptions, :after_handler
end

configure :production do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
  set :show_exceptions, :after_handler
end

# this is required if you want to assume the default path
set :root, File.dirname(__FILE__)



# Arreglo a lo bestia para el force_encoding

unless "".respond_to? :force_encoding
  class String
    def force_encoding(s)
      self
    end
  end
end





Dir.glob("controllers/**/*.rb").each do |f|
  require_relative(f)
end


unless File.exist?("log")
  FileUtils.mkdir("log")
end

if $test_mode
  $log = Logger.new('log/test_app.log')
  $log_sql = Logger.new('log/test_app_sql.log')

else
  $log = Logger.new('log/app.log')
  $log_sql = Logger.new('log/app_sql.log')

end


#$log.info(Encoding.default_external)

require_relative 'model/init.rb'
require_relative 'model/models.rb'
require_relative 'lib/sinatra/partials.rb'


Dir.glob("model/*.rb").each do |f|
  require_relative(f)
end


require 'digest/sha1'





# Internacionalización!
#require 'i18n'


#::I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)







helpers Sinatra::Partials
helpers Sinatra::Mobile
helpers DOIHelpers
helpers HTMLHelpers

helpers do
  # Entrega el acceso al log
  def log
    $log
  end
  def dir_base
    File.expand_path(File.dirname(__FILE__))
  end
  def dir_archivos
    dir=File.expand_path(File.dirname(__FILE__)+"/usr/files")
    FileUtils.mkdir_p(dir) unless File.exist? dir
    dir
  end
  def title(title)
    @title=title
  end
  def scopus_available?
    !ENV['SCOPUS_KEY'].nil?
  end
  def get_title_head
    if @title.length>80
      @title[0..80]+"..."
    else
      @title
    end

  end
  # Entrega el valor para un id de configuración
  def config_get(id)
    Configuracion.get(id)
  end
  # Define el valor para un id de configuración
  def config_set(id,valor)
    Configuracion.set(id,valor)
  end
  def tiempo_sql(tiempo)
    tiempo.strftime("%Y-%m-%d %H:%M:%S")
  end


end




error 403 do
  haml :error403
end
error 404 do
  haml :error404
end





# INICIO

get '/' do
  log.info("Parto en /")
  if session['user'].nil?
    log.info("/ sin id: basico")
    redirect url('/login')
  else
    @user=Usuario[session['user_id']]
    haml :main
  end
end

