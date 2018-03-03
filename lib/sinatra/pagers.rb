# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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