# encoding:utf-8
require 'sequel'
require 'logger'
Sequel::Model.plugin :force_encoding, 'UTF-8' if RUBY_VERSION>="1.9"
# Chanta, ¿no?

if(ENV['USER']=='elecciones' and production?)
  $db=Sequel.mysql(:host=>"192.168.0.10",:user=>'biobio',:password=>'biobio018025', :database=>'biobio2012', :encoding => 'UTF8')
elsif(ENV['USER']=='elecciones' and development?)
  $db=Sequel.mysql(:host=>"192.168.0.10",:user=>'biobio',:password=>'biobio018025', :database=>'biobio2012_dev', :encoding => 'UTF8')

elsif(ENV['USER']=="cdx")
$db=Sequel.mysql(:host=>"localhost",:user=>'root',:password=>'psr-400', :database=>'revsist', :encoding => 'UTF8')

else
#$db=Sequel.mysql(:host=>"mysql.apsique.cl",:user=>'biobio',:password=>'biobio018025', :database=>'biobio2012', :encoding => 'UTF8')
raise("No sé donde conectarme")
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
end

