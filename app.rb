# encoding: UTF-8



require "bundler/setup"
require 'sinatra'
# Vamos a activar el reloader en todos los casos
# Como el sistema está en vivo, es más peligroso hacer lo otro
require 'haml'
require 'logger'


require 'dotenv'
require 'i18n'

Dotenv.load("./.env")
#require 'i18n/backend/fallbacks'


Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end


# If .env doesn't exists, we should call the installer
#
unless File.exist?(".env")
  load('installer.rb')
  BibRevSys::Installer.run!
end
exit 1



set :session_secret, 'super secret2'

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
$log = Logger.new('log/app.log')
$log_sql = Logger.new('log/app_sql.log')



require_relative 'model/init.rb'
require_relative 'model/models.rb'
require_relative 'lib/partials.rb'


Dir.glob("model/*.rb").each do |f|
  require_relative(f)
end


require 'digest/sha1'
enable :logging, :dump_errors, :raise_errors, :sessions

configure :development do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
end

configure :production do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
end





# Internacionalización!
#require 'i18n'


#::I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)





# this is required if you want to assume the default path
set :root, File.dirname(__FILE__)


helpers Sinatra::Partials
helpers Sinatra::Mobile
helpers DOIHelpers
helpers HTMLHelpers

helpers do
  # Entrega el acceso al log
  def log
    $log
  end
  def dir_archivos
    dir=File.expand_path(File.dirname(__FILE__)+"/usr/archivos")
    FileUtils.mkdir_p(dir) unless File.exist? dir
    dir
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

