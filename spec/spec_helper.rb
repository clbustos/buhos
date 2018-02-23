require 'i18n'
require 'fileutils'
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
     @tempfile = Tempfile.new('db.sqlite')
     FileUtils.cp blank_sqlite, @tempfile.path
     ENV['DATABASE_URL']="sqlite://#{@tempfile.path}"
  end
  def close_sqlite
    @tempfile.close
    @tempfile.unlink
  end
end

module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end
end


#RSpec.configure { |c| c.include RSpecMixin }