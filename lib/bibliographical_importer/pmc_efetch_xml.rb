# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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

require 'nokogiri'

#
module BibliographicalImporter
  # Process XML downloaded from PMC Efetch

  module PmcEfetchXml
    class Record
      include ReferenceMethods
      include BibliographicalImporter::CommonRecordAttributes

      attr_reader :xml
      def self.create(xml)
        BibliographicalImporter::PmcEfetchXml::Record.new(xml)
      end

      def initialize(xml)
        @xml=xml
        @authors=[]
        parse_common
      end
      def get_text_at(path)
        xml_r=xml.at(path)
        xml_r.nil? ? nil : xml_r.text.to_s
      end
      def parse_common
        begin
          @uid=get_text_at("PMID")
          @pubmed_id=@uid
          @title=get_text_at("ArticleTitle")
          @authors=xml.xpath(".//AuthorList/Author").map {|v|
            "#{v.at('LastName').text}, #{v.at('ForeName').text}"
          }

#          #$log.info(@authors)

          @journal  =get_text_at("Article/Journal/Title")
          @year     =get_text_at("Article/Journal/JournalIssue/PubDate/Year")
          @volume   =get_text_at("Article/Journal/JournalIssue/Volume")
          @pages    =get_text_at("Article/Pagination")
          @type     =nil
          @doi      =get_text_at("Article/ELocationID[@EIdType='doi']")
          @url=nil

          @abstract =get_text_at("Article/Abstract/AbstractText")

        rescue Exception=>e
          #$log.info("Error:#{vh}")
          raise e
        end

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
      attr_reader :xml_a
      attr_reader :records
      include Enumerable
      def [](x)
        @records[x]
      end
      def each(&block)
        @records.each(&block)
      end
      def initialize(xml_o)
        if xml_o.is_a? PMC::EfetchXMLSummaries
          @xml_a=xml_o
        elsif xml_o.is_a? Nokogiri::XML::Document
          @xml_a=[xml_o]
        end
        @records=[]
        parse_records
      end

      def self.open(filename)
        b=File.open(filename) { |f| Nokogiri::XML(f) }
        Reader.new(b)
      end

      def self.parse(string)
        b=Nokogiri::XML(string)
        Reader.new(b)
      end

      def parse_records
        @xml_a.each do |xml|
          xml.xpath("//PubmedArticle").each do |article|
            #$log.info(article.xpath(".//AuthorList/Author/LastName").text)
            @records.push(BibliographicalImporter::PmcEfetchXml::Record.create(article))
          end
        end

      end
    end
  end
end