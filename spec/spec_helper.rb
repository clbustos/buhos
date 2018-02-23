require 'simplecov'
SimpleCov.start

require 'i18n'
require 'fileutils'
require 'sinatra'
require_relative '../app'

#SimpleCov.formatter = SimpleCov::Formatter::Codecov
# Load available locales
app_path=File.expand_path(File.dirname(__FILE__)+"/..")
::I18n.load_path+=Dir[File.join(app_path, 'config','locales', '*.yml')]
::I18n.config.available_locales = [:es,:en]

# Load rack test
#

require 'rack/test'

ENV['RACK_ENV'] = 'test'



module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
  def configure_test_sqlite
    blank_sqlite=File.expand_path(File.dirname(__FILE__)+"/../db/blank.sqlite")
     @tempdir= Dir.mktmpdir("buhos_test")
     @tempfile= "#{@tempdir}/db_#{Random.rand(1000)}.sqlite"
     FileUtils.cp blank_sqlite, @tempfile
     Buhos.connect_to_db("sqlite://#{@tempfile}")
  end
  def close_sqlite
    FileUtils.rm @tempfile
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
