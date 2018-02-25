require 'simplecov'
SimpleCov.start
require 'sequel'
require 'rspec'
require 'i18n'
require 'fileutils'
require 'rack/test'
require 'tempfile'
require 'logger'
require_relative "../db/create_schema"
require_relative "../lib/buhos/dbadapter"

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL']='sqlite::memory:'


$base=File.expand_path("..",File.dirname(__FILE__))


FileUtils::mkdir_p "#{$base}/log/"

logger_sql = Logger.new("#{$base}/log/app_sql_test.log")

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
  def configure_test_sqlite

    db=Buhos::SchemaCreation.create_db_from_scratch(Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false))

    $db_adapter.use_db(db)
    $db_adapter.update_model_association


    $log.info("DB is:#{$db}")
  end

  def configure_complete_sqlite

    temp=Tempfile.new
    FileUtils.cp "#{$base}/db/db_complete.sqlite", temp.path
    db=Sequel.connect("sqlite://#{temp.path}", :encoding => 'utf8',:reconnect=>false, :keep_reference=>false)

    $db_adapter.use_db(db)
    $db_adapter.update_model_association




    #puts "Adaptador: #{$db_adapter.object_id} - #{Usuario.db.object_id}"
    #puts "Db: #{$db_adapter.current.object_id} - #{$db.object_id} - #{db.object_id}"
    temp
  end

  def close_sqlite
    $log.info("Closing #{$db}")
    #@tempfile.unlink


  end

  def permitted_redirect(url)
    get url
    expect(last_response).to_not be_ok
    expect(last_response.status).to_not eq(403)

  end
end


module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end

end


#RSpec.configure { |c| c.include RSpecMixin }


RSpec::Matchers.define :be_accesible_for_admin do
  match do |actual|
    post '/login' , :user=>'admin', :password=>'admin'
    get actual
    #puts last_response.body
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
  end

  match_when_negated do |actual|
    post '/login' , :user=>'admin', :password=>'admin'
    get actual
    expect(last_response).to_not be_ok
  end
  description do
    "route #{actual} be accesible for admin"
  end


  failure_message do |actual|
    last_response.body=~/<section id='content'>(.+?)<\/section>/m
    show_body=$1.nil? ? last_response.body : $1
    "expected #{actual} be accessible, but status was #{last_response.status} and content was '#{show_body}'"
  end
end


RSpec::Matchers.define :be_accesible do
  match do |actual|
    get actual
    #puts last_response.body
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
  end

  match_when_negated do |actual|
    get actual
    expect(last_response).to_not be_ok
  end
  description do
    "route #{actual} be accesible"
  end
end

RSpec::Matchers.define :be_prohibited do
  match do |actual|
    get actual
    expect(last_response).to_not be_ok
    expect(last_response.status).to eq(403)
  end

  description do
    "route #{actual} be prohibited"
  end
end

