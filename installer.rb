module BibRevSys
  # This modular Sinatra app generates a simple form to install
  # BibSysRev
  class Installer < Sinatra::Base

    helpers Sinatra::Partials
    helpers Sinatra::Mobile
    helpers DOIHelpers
    helpers HTMLHelpers
    register Sinatra::I18n
    register Sinatra::Mensajes

    helpers do
      def permiso(p)
        true
      end
    end

    get '/' do
      redirect '/installer/select_language'
    end
    get '/installer/select_language' do

      haml "installer/select_language".to_sym, :layout=>"installer/layout".to_sym
    end



    post '/installer/select_language' do
      session['language']=params['language'].to_sym
      
      redirect '/basic_data_form'
    end

    get '/basic_data_form' do
      haml "installer/basic_data_form".to_sym, :layout=>"installer/layout".to_sym

    end
  end


end