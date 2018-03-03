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
module Scopus
  module XMLResponse
    
    class Scopus::XMLResponse::Abstractcitationsresponse < XMLResponseGeneric
      attr_reader :h_index # How many records are in the xml
      attr_reader :year_range
      attr_reader :prev_total
      attr_reader :later_total
      attr_reader :column_total
      attr_reader :range_total
      attr_reader :grand_total
      attr_reader :records
      attr_reader :n_records
      def process
        #p @xml
        @h_index=process_path(@xml,"//h-index").to_i
        @year_range=@xml.xpath("//columnHeading").map {|xx| xx.text.to_i}
        @prev_total=process_path(@xml,"//prevColumnTotal").to_i
        @later_total=process_path(@xml,"//laterColumnTotal").to_i
        @column_total=@xml.xpath("//columnTotal").map {|xx| xx.text.to_i}
        @range_total=process_path(@xml,"//rangeColumnTotal").to_i
        @grand_total=process_path(@xml,"//grandTotal").to_i


        @records=xml.xpath("//citeInfo").map do |x|
          scopus_id=process_path(x,".//dc:identifier")

          pcc=process_path(x,".//pcc").to_i
          cc=x.xpath(".//cc").map {|xx| xx.text.to_i}

          lcc=process_path(x,".//lcc").to_i
          #if scopus_id=="SCOPUS_ID:84866769122"
          #  p x
          #  p({:scopus_id=>scopus_id,:pcc=>pcc,:lcc=>lcc,:cc=>cc})
          #end
          {:scopus_id=>scopus_id,:pcc=>pcc,:lcc=>lcc,:cc=>cc}
        end
        #p @records
      end
      def n_records
        @records.length
      end

      def scopus_id_a
        @records.map {|r| r[:scopus_id]}
      end
      def get_record(scopus_id)
        record=@records.find {|r| r[:scopus_id]==scopus_id}
        raise("Record doesn't exists") unless record
        record
      end
      def empty_record?(scopus_id)
        record=get_record(scopus_id)
        record[:cc]==[]
      end
      def citations_by_year(scopus_id)
        record=get_record(scopus_id)
        return nil if record[:cc].length==0
        year_range.each_index.inject({}) {|ac,i|
          ac[@year_range[i]]=record[:cc][i]
          ac
        }
      end
      def citations_outside_range?(scopus_id)
        @grand_total!=@range_total
      end
    end
  end

end
