module Sinatra
  module Messages
    module Helpers
      def add_message(mensaje, type=:info)
        session['messages']||=[]
        session['messages'].push([mensaje,type])
      end
      def add_result(result)
        result.events.each do |event|
          add_message(event[:message], event[:type])
        end
      end

      def print_messages
        if session['messages']
          #$log.info(session['messages'])
          out=session['messages'].map {|men,type|

            "<div class='alert alert-#{type.to_s} #{type.to_s=='error' ? 'alert-danger' : ''}' role='alert'>#{men}</div>\n"
          }
          session.delete("messages")
          out.join()
        else
          ""
        end
      end
    end
    def self.registered(app)
      app.helpers Messages::Helpers
    end
  end
  register Messages
end
