module Sinatra
  module I18n
    module Helpers
      def t(*args)
        ::I18n::t(*args)
      end
      def t_desc_count(term,count)
        "<strong>#{::I18n::t(term)}:</strong>#{count}"
      end
    end

    def self.registered(app)
      app.helpers I18n::Helpers
      #$log.info(app.root)
      unless defined?(app.locales)
        app.set :locales, File.join(app.root, 'locales', '*.yml')
      end
      ::I18n.config.available_locales = [:es,:en]
      ::I18n.load_path+=Dir[app.locales]
      #::I18n.backend.load_translations(app.locales)
    end
  end
  register I18n
end