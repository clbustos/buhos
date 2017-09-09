require 'bibtex'
#require 'citeproc'



module ReferenceIntegrator
# Clase que unifica la lectura de BibTeX de Scopus, Wos y Ebscohost. Si hay otro, lo veremos
  module BibTex
    class Record

      include CommonRecordAttributes
      attr_reader :bv



      COMMON_FIELDS=[:title, :abstract, :journal, :year, :volume, :pages,
                     :language, :affiliation, :doi, :cited, :url, :author]


      def self.create(bibtex_value)
        type=self.determine_type(bibtex_value)
        klass="Record_#{type.capitalize}".to_sym
        ReferenceIntegrator::BibTex.const_get(klass).send(:new, bibtex_value)
      end

      def self.determine_type(bibtex_value)
        if bibtex_value[:source].to_s=="Scopus"
          type=:scopus
        elsif bibtex_value["unique-id"].to_s=~/ISI:/
          type=:wos
        elsif bibtex_value[:url].to_s=~/search\.ebscohost.com/
          type=:ebscohost
        elsif bibtex_value[:url].to_s=~/scielo/
          type=:scielo
        else
          type=:generic
        end
        type
      end

      def initialize(bibtex_value)
        @bv=bibtex_value
        @references_wos=[]
        @references_scopus=[]
        parse_common
        parse_specific
      end

      def parse_common
        COMMON_FIELDS.each do |t|
          send("#{t}=", strip_lines(@bv[t].to_s))
        end
      end

      def authors
        @bv[:author].to_a
      end

      # Determine the type of the reference. It could be infered by fields

      def parse_specific

      end

      def strip_lines(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end

    class Record_Scopus < Record
      def parse_specific
        @references_scopus= @bv["references"].to_s.split("; ") unless @bv['references'].nil?
        @journal_abbr=@bv[:abbrev_source_title].to_s
        @keywords=@bv[:keywords].to_s.split(";  ")
        results=/eid=([^&]+)/.match(@bv[:url])
        @uid=results[0]
      end

      def type
        :scopus
      end

      def cited_references
        @references_scopus
      end
    end


    class Record_Wos < Record
      def quitar_llaves(x)
        x.gsub(/^\{(.+)\}$/, "\\1")
      end

      def parse_common
        COMMON_FIELDS.each do |t|
          send("#{t}=", quitar_llaves(strip_lines(@bv[t].to_s)))
        end
      end

      def parse_specific

        @references_wos= quitar_llaves(@bv["cited-references"].to_s).split(".\n   ") unless @bv['cited-references'].nil?
        @journal_abbr=quitar_llaves(@bv["journal-iso"].to_s)
        @keywords_plus=quitar_llaves(strip_lines(@bv["keywords-plus"].to_s)).split("; ")
        @keywords=quitar_llaves(strip_lines(@bv[:keywords])).split("; ")
        @uid=quitar_llaves(@bv['unique-id'])
      end

      def type
        :wos
      end

      def cited_references
        @references_wos
      end


    end


    class Record_Scielo < Record
      def type
        :scielo
      end

      def parse_specific
        results=/(pid=[^&]+)/.match(@bv[:url])
        @uid=results[0]
      end

      def cited_references
        nil
      end
    end
    class Record_Ebscohost < Record
      def parse_specific
        @keywords=@bv[:keywords].split(", ")

        results=/(db=.+)/.match(@bv[:url])
        @uid=results[0]
      end

      def type
        :ebscohost
      end

      def cited_references
        nil
      end
    end
    class Record_Generic < Record

    end

    class Reader
      attr_reader :bb
      attr_reader :records
      include Enumerable
      def each(&block)
        @records.each(&block)
      end

      def initialize(bibtex_bibliography)
        @bb=bibtex_bibliography
        parse_records
      end

      def self.open(filename)
        b=BibTeX.open(filename, :strip => false)
        Reader.new(b)
      end

      def self.parse(string)
        b=BibTeX.parse(string, :strip => false)
        Reader.new(b)
      end

      def parse_records
        @records=@bb.map {|r| BibTex::Record.create(r)}
      end
    end
  end
end

