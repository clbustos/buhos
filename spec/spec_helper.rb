require 'simplecov'
unless ENV['NO_COV']
  SimpleCov.start do
    add_filter '/spec/'
    add_filter 'lib/scopus/connection.rb' # Is necessary an API scopus to test it
  end
end
require 'sequel'
require 'rspec'
require 'i18n'
require 'fileutils'
require 'rack/test'
require 'tempfile'
require 'logger'
require_relative "../db/create_schema"
require_relative "../lib/buhos/dbadapter"
require_relative 'rspec_matchers'

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL']='sqlite::memory:'


$base=File.expand_path("..",File.dirname(__FILE__))


FileUtils::mkdir_p "#{$base}/log/"

logger_sql = Logger.new("#{$base}/log/spec_sql_test.log")

db=Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false)
Buhos::SchemaCreation.create_db_from_scratch(db)

$db_adapter=Buhos::DBAdapter.new
$db_adapter.logger=logger_sql
$db_adapter.use_db(db)

Sequel::Model.db=$db_adapter

require_relative "../app"

Buhos.connect_to_db($db_adapter)

#puts "#{$db.object_id} - #{$db_adapter.object_id}"

#exit





#SimpleCov.formatter = SimpleCov::Formatter::Codecov
# Load available locales
app_path=File.expand_path(File.dirname(__FILE__)+"/..")
::I18n.load_path+=Dir[File.join(app_path, 'config','locales', '*.yml')]
::I18n.config.available_locales = [:es,:en]

# Load rack test
#



module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
	def is_windows?
		(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	end
  def sr_by_name_id(name)
    rs=SystematicReview[:name=>name]
    rs ? rs[:id] : nil
  end

  def bb_by_name_id(name)
    bb=BibliographicDatabase[name:name]
    bb ? bb[:id] :nil
  end

  def configure_empty_sqlite

    db=Buhos::SchemaCreation.create_db_from_scratch(Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false))
    $db_adapter.use_db(db)
    $db_adapter.update_model_association

    $log.info("DB is:#{$db}")
  end
  def login_admin
    post '/login', :user=>"admin", :password=>"admin"
  end
  def configure_complete_sqlite
	if(is_windows?)
		temppath="#{$base}/spec/usr/db_temp.sqlite"
		FileUtils.cp "#{$base}/db/db_complete.sqlite", temppath
		
		db=Sequel.connect("sqlite:/#{temppath}", :encoding => 'utf8',:reconnect=>false, :keep_reference=>false)
		temp=db
	else
		temp=Tempfile.new
		FileUtils.cp "#{$base}/db/db_complete.sqlite", temp.path
		# check next line. If we can 
		db=Sequel.connect("sqlite:#{temp.path}", :encoding => 'utf8',:reconnect=>false, :keep_reference=>false)
    end
	
    $db_adapter.use_db(db)
    $db_adapter.update_model_association



    #puts "Adaptador: #{$db_adapter.object_id} - #{User.db.object_id}"
    #puts "Db: #{$db_adapter.current.object_id} - #{$db.object_id} - #{db.object_id}"
    temp
  end

  def close_sqlite
    $log.info("Closing #{$db}")
    #$db.disconnect
    #$db_adapter.use_db(nil)
    #$db=nil

  end

  def permitted_redirect(url)
    get url
    expect(last_response).to_not be_ok
    expect(last_response.status).to_not eq(403)

  end

  def check_executable_on_path(exe)
    require 'mkmf'
    find_executable exe
  end
end


module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end

end


#RSpec.configure { |c| c.include RSpecMixin }

