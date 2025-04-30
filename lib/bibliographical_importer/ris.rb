# Copyright (c) 2016-2025, Claudio Bustos Navarrete, Alexis Vielma (thanks for the patience)
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
# encoding: utf-8

require_relative '../ris_reader'

#
module BibliographicalImporter
# Unifies Scopus, WoS, Ebscohost and generic BibTeX formats.
#
  module Ris
    # A BibTex Record
    # Class method create() is a factory, that creates a specific
    # Record_XXX object.
    class Record

      include CommonRecordAttributes
      attr_reader :record



      COMMON_FIELDS=[:title, :abstract, :journal, :year, :volume, :pages,
                     :language, :affiliation, :doi, :cited, :url, :author,
                     :wos_id, :scopus_id, :ebscohost_id, :scielo_id, :refworks_id
      ]

      def self.create(record)
        BibliographicalImporter::Ris::Record.new(record)
      end

      def initialize(record)
        @record=record
        parse_common
        parse_specific

      end
      def get_string(x, separator=" - ")
        if @record[x]
          if @record[x].is_a? Array
            @record[x].join(separator)
          else
            @record[x]
          end
        else
          nil
        end
      end

      def parse_common
        begin
          require 'digest'

          @type=:generic

          if @record['TT']
            @title=get_string('TT')
          elsif @record["TI"]
            @title=get_string('TI')
          elsif @record["T1"]
            @title=get_string('T1')
          end
          @abstract=get_string("AB")
          @author=get_string("AU", " ; ")
          @authors=@record["AU"]
          if @record['JO']
            @journal=get_string('JO')
          elsif @record["JF"]
            @journal=get_string('JF')
          end

          if @record['Y1']
            parts_date=get_string('Y1').split("/")
            @year=parts_date[0]
          elsif @record['PY']
            @year=get_string("PY")
          end

          @volume=get_string("VL")
          @pages="#{get_string("SP")}-#{get_string("EP")}"


          if @record['DO']
            @doi=get_string("DO")
          elsif @record['DI']
            @doi=get_string("DI")
          end

          @keywords=get_string("KW")
          @journal_abbr=get_string("JF")

          if @record['L3']
            l3=get_string('L3')
            if l3=~/^10\./ and @doi.nil?
              @doi=l3
            end
            @url=l3
          end

          @uid=Digest::SHA256.hexdigest "#{get_string("AU")}-#{@year}-#{@title}"
        rescue Exception => e
          #$log.info("Error:#{row}")
          raise e
        end
      end
      def cited_references

      end
      def parse_specific

      end



    end

    class Reader
      include AbstractReader
      include Enumerable
      attr_reader :records
      def [](x)
        @records[x]
      end
      def each(&block)
        @records.each(&block)
      end

      def initialize(ris_bibliography)
        @rb=ris_bibliography
        parse_records
      end

      def self.open(filename)
        Reader.parse(File.open(filename))
        #tc=fix_string(File.read(filename))
        #b=BibTeX.parse(tc, :strip => false)
        #Reader.new(b)
      end

      # BibTex doesn't have a standard reference, so any real provider
      # generates BibTex that brokes bibtex library
      #
      # Also, check if encoding is adequate
      #
      def self.fix_string(string)
        string
      end
      # Parse a BibTex file
      # @param string [String] BibTex text
      # @return Ris::Reader
      def self.parse(string)
        b=::RisReader.new(string)
        b.process
        Reader.new(b)
      end

      def parse_records
        @records=@rb.records.map {|r| Ris::Record.create(r)}.find_all {|r| !r.nil?}
      end
    end

    class Writer
      def self.generate(canonical_documents)
        raise "TODO"
      end
    end

  end
end

