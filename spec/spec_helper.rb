require 'simplecov'
SimpleCov.start
ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL']=nil

require 'rspec'
require 'i18n'
require 'fileutils'
require 'sinatra'
require 'rack/test'
require 'tempfile'




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

    blank_sqlite=File.expand_path(File.dirname(__FILE__)+"/../db/blank.sqlite")

     @tempfile= Tempfile.new
     FileUtils.cp blank_sqlite, @tempfile.path
     sql_con="sqlite://#{@tempfile.path}"
     ENV['DATABASE_URL']=sql_con
     require_relative '../app'
     Buhos.connect_to_db(sql_con)
     $log.info("DB is:#{$db}")
  end

  def close_sqlite
    $log.info("Closing #{$db}")
    #@tempfile.unlink
    $db=nil

  end

  def not_permitted(url)
    get url
    expect(last_response).to_not be_ok
    expect(last_response.status).to eq(403)
  end
  def permitted(url)

    get url
    expect(last_response).to be_ok
    expect(last_response.body).to_not be_empty
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
