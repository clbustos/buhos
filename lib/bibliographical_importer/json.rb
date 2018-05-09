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

#
module BibliographicalImporter
  # Based on Crossref JSON
  # TODO: Create an unique id for this class, to allows use of other JSON formats
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
      include ReferenceMethods
      include BibliographicalImporter::CommonRecordAttributes

      attr_reader :jv
      attr_accessor :references_crossref




      def self.create(json)
        #type=self.determine_type(bibtex_value)
        #klass="Reference_#{type.capitalize}".to_sym
        #BibliographicalImporter::JSON.const_get(klass).send(:new, bibtex_value)

        BibliographicalImporter::JSON::Record.new(json)
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
          #$log.info("Parseando")
          #$log.info(vh["author"])
          @authors=vh["author"].map {|v|
            "#{v["family"]}, #{v["given"]}"
          } unless vh["author"].nil?

#          #$log.info(@authors)

          @journal=vh["container-title"].join(";")
          @year=vh["issued"]["date-parts"][0][0]
          @volume=vh["volume"]
          @pages=vh["page"]
          @type=vh["type"]
          @doi=vh["DOI"]
          @url=vh["URL"]
          @references_crossref=@jv["message"]["reference"]

        rescue Exception=>e
          #$log.info("Error:#{vh}")
          raise e
        end

      end

      def references
        @references_crossref.map {|v|
          Reference.new(v)
        } unless @references_crossref.nil?
      end


      def author
        #$log.info(@authors)
        @authors.join (" and ")

      end

      # Determine the type of the reference. It could be infered by fields



      def strip_lines(value)
        value.to_s.gsub(/\n\s*/, ' ')
      end
    end

    class Reader
      include AbstractReader
      include Enumerable
      attr_reader :jb
      attr_reader :records

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
        @records=@jb.map {|r| BibliographicalImporter::JSON::Record.create(r)}
      end
    end
  end
end