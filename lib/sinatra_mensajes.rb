module Sinatra
  module Mensajes
    module Helpers
      def agregar_mensaje(mensaje,tipo=:info)
        session['mensajes']||=[]
        session['mensajes'].push([mensaje,tipo])
      end
      def agregar_resultado(result)
        result.events.each do |event|
          agregar_mensaje(event[:message],event[:type])
        end
      end

      def imprimir_mensajes
        if session['mensajes']
          #$log.info(session['mensajes'])
          out=session['mensajes'].map {|men,tipo|

            "<div class='alert alert-#{tipo.to_s} #{tipo.to_s=='error' ? 'alert-danger' : ''}' role='alert'>#{men}</div>\n"
          }
          session.delete("mensajes")
          out.join()
        else
          ""
        end
      end
    end
    def self.registered(app)
      app.helpers Mensajes::Helpers
    end
  end
  register Mensajes
end
