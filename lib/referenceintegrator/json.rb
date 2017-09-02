require 'bibtex'
#require 'citeproc'

module ReferenceIntegrator
  # Based on Crossref JSON
  module JSON
    # Process references inside JSON
    class Reference
      def initialize(v)
        @v=v
      end
      def doi
        @v['DOI']
      end
      def pages
        if @v['first-page'] and @v['last-page']
          "#{@v['first-page']}-#{@v['last-page']}"
        else
          ""
        end
      end
      def doi_s
        doi ? "doi:#{doi}":""
      end
      def to_s
        if @v['author'] and @v['article-title']
          "#{@v['author']} (#{@v['year']}). #{@v['article-title']}. #{@v['journal-title']}, #{@v['volume']}, #{pages}. #{doi_s}"
        elsif @v['DOI']
          doi_s
        else
          @v.map {|v| "#{v[0]}:#{v[1]}"}.join(";")
        end
      end
    end
    class Record
      include MetodosReferencia
      include ReferenceIntegrator::CommonRecordAttributes

      attr_reader :jv
      attr_accessor :references_crossref




      def self.create(json)
        #type=self.determine_type(bibtex_value)
        #klass="Reference_#{type.capitalize}".to_sym
        #ReferenceIntegrator::JSON.const_get(klass).send(:new, bibtex_value)

        ReferenceIntegrator::JSON::Record.new(json)
      end

      def initialize(json_value)
        @jv=json_value
        @authors=[]
        parse_common


      end
      def parse_common
        begin
          vh=@jv["message"]

          @uid=vh["URL"]
          @title=vh["title"].join(";")
          $log.info("Parseando")
          $log.info(vh["author"])
          @authors=vh["author"].map {|v|
            "#{v["family"]}, #{v["given"]}"
          } unless vh["author"].nil?

#          $log.info(@authors)

          @journal=vh["container-title"].join(";")
          @year=vh["issued"]["date-parts"][0][0]
          @volume=vh["volume"]
          @pages=vh["page"]
          @type=vh["type"]
          @doi=vh["DOI"]
          @url=vh["URL"]
          @references_crossref=@jv["message"]["reference"]

        rescue Exception=>e
          $log.info("Error:#{vh}")
          raise e
        end

      end

      def references
        @references_crossref.map {|v|
          Reference.new(v)
        } unless @references_crossref.nil?
      end


      def author
        $log.info(@authors)
        @authors.join (" and ")

      end

      # Determine the type of the reference. It could be infered by fields



      def strip_lines(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end

    class Reader
      attr_reader :jb
      attr_reader :records
      include Enumerable
      def [](x)
        @records[x]
      end
      def each(&block)
        @records.each(&block)
      end
      def initialize(json_bib)
        @jb=json_bib
        parse_records
      end

      def self.open(filename)
        b=::JSON.parse(File.read(filename))
        Reader.new(b)
      end

      def self.parse(string)
        b=::JSON.parse(string)
        Reader.new(b)
      end

      def parse_records
        @records=@jb.map {|r| ReferenceIntegrator::JSON::Record.create(r)}
      end
    end
  end
end