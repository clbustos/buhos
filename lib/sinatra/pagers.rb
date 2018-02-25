module Sinatra
  module Pagers
    class Pager
      attr_reader :pagina,:busqueda, :cpp, :max_page, :orden
      def initialize
        @pagina=1
        @busqueda=nil
        @cpp=20
        @max_page=nil
        @orden=nil
        @orden_col=nil
        @orden_dir=nil
      end
      def orden=(orden)
        @orden=orden
        @orden_col, @orden_dir=@orden.split("__")
      end
      def pagina=(i)
        @pagina = i.to_i < 0 ? 1 : i.to_i

      end
      def busqueda=(b)
        b=b.to_s.chomp
        @busqueda= (b=="" ? nil : b)
      end
      def cpp=(cpp)
        @cpp=cpp.to_i if cpp.to_i>0
      end
      def max_page=(max_page)
        @max_page=max_page.to_i
        @pagina=1 if @pagina>@max_page
      end

      def ajustar_query(query)
        query=query.offset((@pagina-1)*@cpp).limit(@cpp)
        if @orden
          order_o= (@orden_dir=='asc') ? @orden_col.to_sym : Sequel.desc(@orden_col.to_sym)
          query=query.order(order_o)
        end
        query
      end


    end

    module Helpers
      def  get_pager
        pager=Pager.new
        $log.info(params)
        [:pagina,:busqueda,:cpp, :orden].each {|prop|
          pager.send("#{prop}=",params[prop.to_s]) if params[prop.to_s]
        }
        pager
      end
    end
    def self.registered(app)
      app.helpers Pagers::Helpers
    end
  end
  register Pagers
end