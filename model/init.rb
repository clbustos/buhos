# encoding:utf-8
require 'sequel'
require 'logger'

require 'dotenv'

require_relative "../lib/buhos/dbadapter"
if ENV['RACK_ENV'].to_s != "test"
  Dotenv.load("../.env")
end


module Buhos

  def self.connect_to_db(db,keep_reference=true)

    $db.disconnect if !$db.nil? and $db.is_a? Sequel::Database
    if db.is_a? Sequel::Database or db.is_a? Buhos::DBAdapter
      $db=db
    else
      $db=Sequel.connect(db, :encoding => 'utf8',:reconnect=>true, :keep_reference=>keep_reference)
    end



    begin
      $db.run("SET NAMES UTF8")
    rescue Sequel::DatabaseError
      # Not available
    end
    begin
      $db.run("PRAGMA encoding='UTF-8'")
    rescue Sequel::DatabaseError
      # Not available
    end

    $log_sql = Logger.new(File.dirname(__FILE__)+'/../log/app_sql.log')
    $db.loggers << $log_sql
    $db
  end
end

#$log.info(ENV['RACK_ENV'])
#$log.info(ENV['DATABASE_URL'])

Sequel::Model.plugin :force_encoding, 'UTF-8' if RUBY_VERSION>="1.9"
# Bad, isn't?

if ENV['JAWSDB_URL'] and ENV['USE_JAWSDB']=='true'
  url_mysql= ENV['JAWSDB_URL'].sub("mysql:","mysql2:")
  Buhos.connect_to_db(url_mysql)
else
  Buhos.connect_to_db(ENV['DATABASE_URL'], ENV['RACK_ENV'].to_s != "test")
  $log.info("Init app connects to :#{ENV['DATABASE_URL']}")
end


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
  inflect.irregular 'resolucion', 'resoluciones'
  inflect.irregular 't_clase', 't_clases'
  inflect.irregular 'tag_en_cd', 'tags_en_cds'
  inflect.irregular 'tag_en_clase', 'tags_en_clases'
  inflect.irregular 'tag_en_referencia_entre_cn', 'tags_en_referencias_entre_cn'
  inflect.irregular 'mensaje_rs', 'mensajes_rs'
  inflect.irregular 'mensaje_rs_visto', 'mensajes_rs_vistos'
  inflect.irregular 'archivo_cd', 'archivos_cds'
  inflect.irregular 'archivo_rs', 'archivos_rs'
  inflect.irregular 'asignacion_cd','asignaciones_cds'
  inflect.irregular 'tag_en_referencia_entre_cn', 'tags_en_referencias_entre_cn'
end

