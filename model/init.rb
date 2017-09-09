# encoding:utf-8
require 'sequel'
require 'logger'

require 'dotenv'
Dotenv.load("../.env")

Sequel::Model.plugin :force_encoding, 'UTF-8' if RUBY_VERSION>="1.9"
# Chanta, ¿no?

if ENV['JAWSDB_URL'] and ENV['USE_JAWSDB']=='true'
  url_mysql= ENV['JAWSDB_URL'].sub("mysql:","mysql2:")
  $db=Sequel.connect(url_mysql, :encoding => 'utf8',:reconnect=>true)
else
  $db=Sequel.connect(ENV['DATABASE_URL'], :encoding => 'utf8',:reconnect=>true)
end

$db.run("SET NAMES UTF8")
$log_sql = Logger.new(File.dirname(__FILE__)+'/../log/app_sql.log')

$db.loggers << $log_sql



#before do
#  content_type :html, 'charset' => 'utf-8'
#end





Sequel.inflections do |inflect|
  inflect.irregular 'rol','roles'
  inflect.irregular 'configuracion','configuraciones'  
  inflect.irregular 'permisos_rol','permisos_roles'
  inflect.irregular 'grupo_usuario','grupos_usuarios'
  inflect.irregular 'revision_sistematica','revisiones_sistematicas'  
  inflect.irregular 'trs_organizacion','trs_organizaciones'
  inflect.irregular 'base_bibliografica','bases_bibliograficas'
  inflect.irregular 'canonico_documento','canonicos_documentos'
  inflect.irregular 'referencia_registro', 'referencias_registros'
  inflect.irregular 'decision', 'decisiones'
end

