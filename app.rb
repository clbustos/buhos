# encoding: UTF-8

$:.unshift(File.dirname(__FILE__)+"/.")


require "bundler/setup"
require 'sinatra'
# Vamos a activar el reloader en todos los casos
# Como el sistema está en vivo, es más peligroso hacer lo otro
require "sinatra/reloader" #if development?
require 'haml'
# Arreglo a lo bestia para el force_encoding
unless "".respond_to? :force_encoding
  class String
    def force_encoding(s)
      self
    end
  end
end


Dir.glob("controllers/**/*.rb").each do |f|
  require(f)
end

Dir.glob("lib/*.rb").each do |f|
  require(f)
end


require 'logger'
if !File.exists?("log")
  FileUtils.mkdir("log")
end
$log = Logger.new('log/app.log')
$log_sql = Logger.new('log/app_sql.log')

require 'model/init.rb'
require 'model/models.rb'
require 'lib/partials.rb'


Dir.glob("model/*.rb").each do |f|
  require(f)
end


require 'digest/sha1'




enable :logging, :dump_errors, :raise_errors, :sessions

configure :development do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions 
  c.also_reload("controllers/*.rb")
  c.also_reload("lib/*.rb")
  c.also_reload("model/*.rb")
end

configure :production do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
end



helpers Sinatra::Partials
helpers Sinatra::Mobile

# Internacionalización!
require 'i18n'



module Sinatra
  module I18n
    module Helpers
      def t(*args)
        ::I18n::t(*args)
      end
      def _(*args)
        ::I18n::t(*args)
      end
    end

    def self.registered(app)
      app.helpers I18n::Helpers

      unless defined?(app.locales)
        app.set :locales, File.join(app.root, 'locales', '*.yml')
      end

      ::I18n.load_path+=Dir[app.locales]
    end
  end
  register I18n
end



# this is required if you want to assume the default path
set :root, File.dirname(__FILE__)

# an alternative would be to set the locales path
#set :locales, File.join(File.dirname(__FILE__), 'locales/es.yml')

# then just register the extension
#register Sinatra::I18n


helpers do
  # Entrega el acceso al log  
  def log
    $log
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
  def rol_usuario
    if(!session['user'].nil?)
      "invitado"
    else
      session['rol_id']
    end
  end
  def presentar_usuario
    #$log.info(session)
    if(!session['user'].nil?)
      haml :usuario
    else
      haml :visitante
    end
  end
  
  # Verifica que la persona tenga un permiso específico
  def permiso(per)
    #log.info(session['permisos'])    
    if(session['user'].nil?)
      false
    else
      if(session['rol_id']=='administrador' and Permiso[per].nil?)
        Permiso.insert(:id=>per, :descripcion=>'Por hacer')
        Rol['administrador'].add_permiso(Permiso[per])
        true
      elsif session['permisos'].include? per
        true
      else
        false
      end
    end
  end

  
    def authorize(login, password)
    u=Usuario.filter(:login=>login,:password=>Digest::SHA1.hexdigest(password))
    $log.info(u.first)
    if(u.first)
      user=u.first
      session['user']=user[:login]
      session['user_id']=user[:id]
      session['nombre']=user[:nombre]
      session['rol_id']=user[:rol_id]      
      session['permisos']=user.permisos.map {|v| v.id}
      true
    else
      false
    end
  end

    def desautorizar
    session.delete('user')
  end

   def agregar_mensaje(mensaje,tipo=:info)
    session['mensajes']||=[]
    session['mensajes'].push([mensaje,tipo])
  end
  def imprimir_mensajes
    if(session['mensajes'])
      out=session['mensajes'].map {|men,tipo|
        "<div class='#{tipo.to_s}'>#{men}</div>\n"
      }
      session.delete("mensajes")
      out.join()
    else
      ""
    end
  end
  def url(ruta)
    if @mobile
      "/mob#{ruta}"
    else
      ruta
    end
  end

end




error 403 do
  haml :error403
end
error 404 do
  haml :error404
end

before do
  
end

before do
  if session['user'].nil?
    request.path_info='/login'
  end
end

# INICIO

get '/' do
  log.info("Parto en /")
  if session['user'].nil?
    log.info("/ sin id: basico")
    redirect url('/login')
  else
    #begin
      redirect url('/'+session['rol_id'])
      raise "Error"
    #rescue
    #  session['id']=nil
    #  redirect('/error')
    #end
  end
end

get '/login' do
  haml :login
end

post '/login' do
  if(authorize(params['user'], params['password']))
    agregar_mensaje "Autentificación exitosa"
    log.info("Autentificación exitosa de #{params['user']}")
    redirect(url("/"))
  else
    agregar_mensaje "Fallo en la autentificacion",:error
    redirect(url("/login"))
  end
end


get '/logout' do
  desautorizar
  redirect(url('/login'))
end
                                                             




