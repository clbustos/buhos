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
    class PagerCdQueryAdapter
      attr_reader :cds_out
      def initialize(pager, cds_pre)
        @pager=pager
        @cds_pre=cds_pre
        @cds_out=@cds_pre
        process
      end
      def process
        if @pager.query.to_s!=""
          cd_ids=@cds_pre.find_all {|v|
            v[:title].include? @pager.query or v[:author].include? @pager.query
          }.map {|v| v[0]}
          @cds_out=@cds_pre.where(:id => cd_ids)
        end
      end
    end

    class PagerAdsQueryAdapter
      attr_reader :cds_out
      def initialize(pager, ads, cds_pre, no_query:false)
        @pager=pager
        @ads=ads
        @cds_pre=cds_pre
        @cds_out=@cds_pre
        @no_query=no_query
        process
      end

      def process
        cd_ids=@cds_pre.map(:id)
        if @pager.extra[:decision] and @pager.extra[:decision]!="_no_"
          cd_ids_decision=@ads.decision_by_cd.find_all {|v|
            @pager.extra[:decision]==v[1]
          }.map {|v| v[0]}
          cd_ids=cd_ids & cd_ids_decision
        end
        if @pager.extra[:tag_select]
          selected_tags=[@pager.extra[:tag_select]].flatten
          #$log.info(selected_tags)
          sr=@ads.systematic_review
          cd_id_tag=selected_tags.map {|tag_id|
            TagInCd.cds_rs_tag(sr,Tag[tag_id],true).map(:id)
          }.flatten.uniq
          cd_ids=cd_ids & cd_id_tag
        end

        if @pager.query and !@no_query
          query=@pager.query
          query="title(#{@pager.query})" unless query=~/\(|\)/
          sp=Buhos::SearchParser.new
          sp.parse(query)
          cd_ids = cd_ids & @cds_pre.where(Sequel.lit(sp.to_sql)).select_map(:id)
        end

        @cds_out=@cds_pre.where(:id => cd_ids)
      end
    end

    class Pager
      # Current page
      attr_reader :page
      # dataset string to be processed
      attr_reader :query
      # Number of object on each page
      attr_reader :cpp
      # Maximum number of pages
      attr_reader :max_page
      # String, with forma "<col>__<direction>". Direction could be desc (default) or asc
      attr_reader :order
      # Number of records
      attr_reader :n_records
      # Extra parameters
      attr_accessor :extra
      def initialize
        @page=1
        @query=nil
        @extra={}
        @cpp=20
        @max_page=nil
        @n_records=nil
        @order=nil
        @order_col=nil
        @order_dir=nil
      end
      # Get an Dataset of CanonicalDocuments and returns a new one, with all pager settings applied
      # Including using 'dataset' to select using title or author
      # 'order'
      def adapt_cds(cds_pre)
        pcqa=PagerCdQueryAdapter.new(self, cds_pre)
        @max_page=(pcqa.cds_out.count/self.cpp.to_f).ceil
        adjust_page_order(pcqa.cds_out)
      end
      # Adapt the cds_pre dataset, using decisions made by a user
      # @param ads [AnalysisUserDecision]
      # @param cds_pre [Sequel::Dataset]
      def adapt_ads_cds(ads, cds_pre, no_query:false)
        paqa=PagerAdsQueryAdapter.new(self, ads, cds_pre, no_query: no_query)
        @max_page=(paqa.cds_out.count/self.cpp.to_f).ceil
        adjust_page_order(paqa.cds_out)
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
      # Retrieves the records to be shown, adjusting by page and order
      def adjust_page_order(dataset)
        @n_records=dataset.count
        dataset=dataset.offset((@page-1)*@cpp).limit(@cpp)
        if @order
          order_o= (@order_dir=='asc') ? @order_col.to_sym : Sequel.desc(@order_col.to_sym)
          dataset=dataset.order(order_o)
        end
        dataset
      end

      def current_first_record
        1+(@page-1)*@cpp
      end
      def current_last_record
        if @page==@max_page
          @n_records
        else
          @page*@cpp
        end
      end

      def uri_encode(element_to_delete=nil)
        hash_to_encode=self.extra.inject({}) {|ac,v|
          if(v[1].is_a? Array)
            ac["#{v[0]}[]"]=v[1]
          else
            ac[v[0]]=v[1]
          end
          ac
        }
        hash_to_encode[:query]    = self.query
        hash_to_encode[:order]    = self.order
        hash_to_encode.delete(element_to_delete) unless element_to_delete.nil?
        "&"+URI.encode_www_form(hash_to_encode)
      end
    end

    # Helpers for Module Pagers
    module Helpers
      # Retrieve a pager object.
      # Params are: page, dataset, cpp, order
      def  get_pager(extra=[])
        pager=Pager.new
        [:page,:query,:cpp, :order].each {|prop|
          pager.send("#{prop}=",params[prop.to_s]) if params[prop.to_s]
        }
        extra.each {|prop|
          pager.extra[prop]=params[prop.to_s] if params[prop.to_s]
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