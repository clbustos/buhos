require 'bibtex'
#require 'citeproc'

module ReferenceIntegrator
  # Based on Crossref JSON
  module CSV
    # Process references inside JSON

    class Record_Refworks
      include MetodosReferencia
      include ReferenceIntegrator::CommonRecordAttributes

      attr_reader :row


      def self.create(row)
        #type=self.determine_type(bibtex_value)
        #klass="Reference_#{type.capitalize}".to_sym
        #ReferenceIntegrator::JSON.const_get(klass).send(:new, bibtex_value)
        ReferenceIntegrator::CSV::Record_Refworks.new(row)
      end

      def initialize(row_value)
        @row=row_value
        @authors=[]
        parse_common
      end

      def parse_common
        ##$log.info(@row)
        begin
          require 'digest'

          @type="refworks"

          @title=row["Title Primary"]
          @abstract=row["Abstract"]
          @authors=row["Authors, Primary"].split(";")
          @journal=row["Periodical Full"]
          @year=row["Pub Year"]
          @volume=row["Volume"]
          @pages="#{row['Start Page']}-#{row['Other Pages']}"
          @doi=row["DOI"]
          @doi=nil if @doi!~/10./
          @keywords=row["Keywords"]
          @url=row["URL"]
          @journal_abbr=row["Periodical Abbrev"]
          @uid=digest=Digest::SHA256.hexdigest "#{row["Authors, Primary"]}-#{@year}-#{@title}"
        rescue Exception => e
          #$log.info("Error:#{row}")
          raise e
        end

      end

      def author
        @authors.join (" and ")
      end

      # Determine the type of the reference. It could be infered by fields
      def cited_references
        nil
      end


      def strip_lines(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end

    class Reader
      attr_reader :csv
      attr_reader :records
      attr_reader :base
      include Enumerable

      def [](x)
        @records[x]
      end

      def each(&block)
        @records.each(&block)
      end

      def initialize(csv_o, base)
        @csv=csv_o
        @base=base
        parse_records
      end

      def self.open(filename)
        raise "Not implemented"
      end

      def self.parse(string, base)
        require 'csv'
        b=::CSV.parse(string, :headers => true)
        Reader.new(b, base)
      end

      def parse_records
        #$log.info(base)
        if base=="refworks"
          @records=@csv.map {|r| ReferenceIntegrator::CSV::Record_Refworks.create(r)}
        else
          raise "TODO"
        end
      end
    end
  end
end