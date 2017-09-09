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
