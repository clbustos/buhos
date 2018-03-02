module Sinatra
  module Pagers
    class Pager
      attr_reader :page,:query, :cpp, :max_page, :order
      def initialize
        @page=1
        @queyr=nil
        @cpp=20
        @max_page=nil
        @order=nil
        @order_col=nil
        @order_dir=nil
      end
      def order=(order)
        @order=order
        @order_col, @order_dir=@order.split("__")
      end
      def page=(i)
        @page = i.to_i < 0 ? 1 : i.to_i

      end
      def query=(b)
        b=b.to_s.chomp
        @query= (b=="" ? nil : b)
      end
      def cpp=(cpp)
        @cpp=cpp.to_i if cpp.to_i>0
      end
      def max_page=(max_page)
        @max_page=max_page.to_i
        @page=1 if @page>@max_page
      end

      def adjust_query(query)
        query=query.offset((@page-1)*@cpp).limit(@cpp)
        if @order
          order_o= (@order_dir=='asc') ? @order_col.to_sym : Sequel.desc(@order_col.to_sym)
          query=query.order(order_o)
        end
        query
      end


    end

    module Helpers
      def  get_pager
        pager=Pager.new
        $log.info(params)
        [:page,:query,:cpp, :order].each {|prop|
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