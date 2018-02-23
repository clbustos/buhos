require 'i18n'

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
end

module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end
end


#RSpec.configure { |c| c.include RSpecMixin }