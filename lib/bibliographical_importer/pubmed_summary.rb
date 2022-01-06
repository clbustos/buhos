# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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
  # Process Pubmed Summaries (nbib files)
  module PubmedSummary



    class Record
      include ReferenceMethods
      include BibliographicalImporter::CommonRecordAttributes

      attr_reader :ps_value


      def self.create(record)
        BibliographicalImporter::PubmedSummary::Record.new(record)
      end

      def initialize(ps_value)
        @ps_value=ps_value
        @authors=[]
        parse_common
      end

      def parse_common
        ##$log.info(@row)
        begin
          require 'digest'

          @type=:pubmed

          @title    =strip_lines(ps_value["TI"]).gsub(/\s+/," ")
          @abstract =ps_value["AB"]
          if ps_value["FAU"].nil?
            @authors=[]
          elsif ps_value["FAU"].is_a? String
            @authors=[ps_value["FAU"]]
          else
            @authors=ps_value["FAU"]
          end
          @journal  =ps_value["JT"]
          @year     =ps_value["DP"].gsub("\D+","")
          @volume   =ps_value["VI"]
          @pages    = ps_value["PG"]
          @pmid     = ps_value["type"]


          if  ps_value["LID"].nil?
            @doi=nil
          elsif  ps_value["LID"].is_a? Array
            value_with_doi = ps_value["LID"].find {|val|
                val=~/\[doi\]/
            }
            @doi= value_with_doi.gsub(/\s*\[doi\]/,"") if !value_with_doi.nil?
          else
            @doi=ps_value["LID"].gsub(/\s*\[doi\]/,"") if ps_value["LID"]=~/\[doi\]/
          end
          @keywords=ps_value["MH"]
          @journal_abbr=ps_value["TA"]
          @uid="PMID:#{@pmid}"
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
      attr_reader :records
      attr_reader :base
      include Enumerable

      def [](x)
        @records[x]
      end

      def each(&block)
        @records.each(&block)
      end

      def initialize(parser_o)
        @parser_o=parser_o
        parse_records
      end

      def self.open(filename)
        raise "Not implemented"
      end

      def self.parse(string)
        require 'ref_parsers'
        parser = RefParsers::PubMedParser.new
        b=parser.parse(string)
        Reader.new(b)
      end

      def parse_records
        @records=@parser_o.map {|r|
          BibliographicalImporter::PubmedSummary::Record.create(r)
        }
      end
    end
  end
end