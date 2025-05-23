# Copyright (c) 2016-2025, Claudio Bustos Navarrete
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
#

#
module BibliographicalImporter
  # Process CSV.
  module CSV

    # A flexible parser for CSV. Works for Bsv and Scielo
    class Record_Generic
      include ReferenceMethods
      include BibliographicalImporter::CommonRecordAttributes

      attr_reader :row

      STANDARD_FIELDS={
        "ID"=>:uid,
        "Title"=>:title,
        "Authors"=>:authors_parse,
        "Author(s)"=>:authors_parse,
        "Journal"=>:journal,
        "Publication year"=>:year,
        "Keyword(s)"=>:keywords_parse,
        "Fulltext URL"=>:url,
        "Abstract"=>:abstract,
        "Volume number"=>:volume,
        "Issue number"=>:issue,
        "DOI"=>:doi}

      def self.create(row)
        BibliographicalImporter::CSV::Record_Generic.new(row)
      end

      def initialize(row_value)
        @row=row_value
        @authors=[]
        parse_common
      end

      def authors_parse=(author_string)
        if author_string.include? ";"
          @authors=author_string.split(";").map {|v| v.strip}
        elsif author_string.include? ","
          @authors=author_string.split(",").map {|v| v.strip}
        end
      end
      def keywords_parse=(keyword_string)
        @keywords=keyword_string
      end

      def parse_common
        ##$log.info(@row)
        begin
          require 'digest'

          @type="generic"
          STANDARD_FIELDS.each_pair do |field, met|
            if !row[field.to_s].nil?
              self.send("#{met}=".to_sym, row[field.to_s].strip)
            elsif !row["#{field} "].nil?
              self.send("#{met}=".to_sym, row["#{field} "].strip)
            end
          end
          if @uid.nil?
            @uid=Digest::SHA256.hexdigest "#{author}-#{@year}-#{@title}"
          end
        rescue Exception => e
          #$log.info("Error:#{row}")
          raise e
        end

      end

      def author
        @authors.join(" and ")
      end

      # Determine the type of the reference. It could be inferred by fields
      def cited_references
        nil
      end


      def strip_lines(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end


    class Record_Refworks
      include ReferenceMethods
      include BibliographicalImporter::CommonRecordAttributes

      attr_reader :row


      def self.create(row)
        #type=self.determine_type(bibtex_value)
        #klass="Reference_#{type.capitalize}".to_sym
        #BibliographicalImporter::JSON.const_get(klass).send(:new, bibtex_value)
        BibliographicalImporter::CSV::Record_Refworks.new(row)
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
          @authors=row["Authors, Primary"].split(";") unless row["Authors, Primary"].nil?
          @journal=row["Periodical Full"]
          @year=row["Pub Year"]
          @volume=row["Volume"]
          @pages="#{row['Start Page']}-#{row['Other Pages']}"
          @doi=row["DOI"]
          @doi=nil if @doi!~/10./
          @keywords=row["Keywords"]
          @url=row["URL"]
          @journal_abbr=row["Periodical Abbrev"]
          @uid=Digest::SHA256.hexdigest "#{row["Authors, Primary"]}-#{@year}-#{@title}"
        rescue Exception => e
          #$log.info("Error:#{row}")
          raise e
        end

      end

      def author
        @authors.join(" and ")
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
      include AbstractReader
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
          @records=@csv.map {|r| BibliographicalImporter::CSV::Record_Refworks.create(r)}
        else
          @records=@csv.map {|r| BibliographicalImporter::CSV::Record_Generic.create(r)}
        end
      end
    end
  end
end