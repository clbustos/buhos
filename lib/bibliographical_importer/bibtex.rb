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
# encoding: utf-8

require 'bibtex'

#
module BibliographicalImporter
# Unifies Scopus, WoS, Ebscohost and generic BibTeX formats.
#
  module BibTex
    # A BibTex Record
    # Class method create() is a factory, that creates a specific
    # Record_XXX object.
    class Record

      include CommonRecordAttributes
      attr_reader :bv



      COMMON_FIELDS=[:title, :abstract, :journal, :year, :volume, :pages,
                     :language, :affiliation, :doi, :cited, :url, :author,
                     :wos_id, :scopus_id, :ebscohost_id, :scielo_id, :refworks_id
      ]

      def self.create(bibtex_value)
		    return nil if (bibtex_value.is_a? BibTeX::Error) or (bibtex_value.is_a? BibTeX::Comment) 
        type=self.determine_type(bibtex_value)
        klass="Record_#{type.capitalize}".to_sym
        BibliographicalImporter::BibTex.const_get(klass).send(:new, bibtex_value)
      end

      def self.determine_type(bibtex_value)
        if bibtex_value[:source].to_s=="Scopus"
          type=:scopus
        elsif bibtex_value["unique-id"].to_s=~/(ISI|WOS):/
          type=:wos
        elsif bibtex_value[:url].to_s=~/search\.ebscohost.com/ or bibtex_value[:url].to_s=~/research\.ebsco\.com/
          type=:ebscohost
        elsif bibtex_value[:url].to_s=~/scielo/ or bibtex_value[:publisher]=~/scielo/
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
        check_title
        check_journal
        check_year
      end

      def parse_common
        COMMON_FIELDS.each do |t|
          send("#{t}=", strip_lines(@bv[t].to_s))
        end
        # pmid is changed to pubmed_id
        #if @bv['pmid'].to_s!=""
        #  @pubmed_id=@bv['pmid'].to_s
        #end
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
      # Many reference systems, like Mendelay and Scopus, and some databases (Scopus) adds extra {} at titles. Better remove it
      def check_title
        @title=title.gsub(/[\{\}]/,"")
      end
      # Scielo adds extra {} on journal titles
      def check_journal
        @journal=journal.gsub(/[\{\}]/,"")
      end
      # Some ($$&#$%(#$#)) add a complete date on year field. Just remove all that is not a
      # 4 digit sequence
      def check_year
        if year.include? "/"
          @year=year.split("/")[0]
        elsif year=~/(\d{4,4})[a-zA-Z]/
          $log.info($1)
          @year=$1
        end
      end


    end

    class Record_Scopus < Record
      def parse_specific
        @references_scopus= @bv["references"].to_s.split("; ") unless @bv['references'].nil?
        @journal_abbr=@bv[:abbrev_source_title].to_s
        @keywords=@bv[:keywords].to_s.split(";  ")
        results=/eid=([^&]+)/.match(@bv[:url])
        @uid=results[0]
        @scopus_id=results[0]

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
        @references_wos= quitar_llaves(@bv["cited-references"].to_s).split(".\n").map {|v| v.strip} unless @bv['cited-references'].nil?
        @journal_abbr=quitar_llaves(@bv["journal-iso"].to_s)
        @keywords_plus=quitar_llaves(strip_lines(@bv["keywords-plus"].to_s)).split("; ")
        @keywords=quitar_llaves(strip_lines(@bv[:keywords])).split("; ")
        @uid=quitar_llaves(@bv['unique-id'])
        @wos_id = @uid
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
        @scielo_id=@uid
      end

      def cited_references
        nil
      end
    end

    class Record_Ebscohost < Record
      def parse_specific
        @keywords=@bv[:keywords].nil? ? [] : @bv[:keywords].split(", ")
        results=/((?:db|id)=.+)/.match(@bv[:url])
        @uid=results[0]
        @ebscohost_id=@uid
      end

      def type
        :ebscohost
      end

      def cited_references
        nil
      end
    end

    class Record_Generic < Record
      def parse_specific
        if @doi.to_s!=""
          uid="doi:#{@doi}"
        else
          self.extend ReferenceMethods
          uid=ref_apa_6_brief[0..255]
        end
        @uid=uid
      end
      def cited_references
        nil
      end
      def type
        :generic
      end
    end

    class Reader
      include AbstractReader
      include Enumerable
      attr_reader :bb
      attr_reader :records
      def [](x)
        @records[x]
      end
      def each(&block)
        @records.each(&block)
      end

      def initialize(bibtex_bibliography)
        @bb=bibtex_bibliography
        parse_records
      end

      def self.open(filename)
        tc=fix_string(File.read(filename))
        b=BibTeX.parse(tc, :strip => false)
        Reader.new(b)
      end

      # BibTeX doesn't have a strict standard, so providers may generate BibTeX
      # entries that break the bibtex library.
      #
      # Additionally, check if the encoding is correct.
      #
      def self.fix_string(string)
        scielo_mode= string.include? "publisher = {scielo}"
        ebscohost_mode = string.include? "research.ebsco.com"
        string=string.encode("UTF-8", invalid: :replace, replace:"?")
        string.gsub!("\u00A0","_") # nonbreaking space!


        string.each_line.map { |line|
          #puts line
          if line=~/^\s*\@.+\{(.+),\s*$/
            #puts "\n***Es intro***:#{line}\n"
            parts=line.split("{")
            parts[1]=parts[1].gsub(/[^0-9a-zA-Z]/,"").strip+","
            #$log.info(parts)
            #p parts
            parts.join("{")
          elsif ebscohost_mode and line=~/^\s*([a-z]+)\s*=\s*\"(.+)",\s*$/
            tag=$1
            inside=$2.gsub('"',"").gsub("{","").gsub("}","")
            out="#{tag} = {#{inside}},\n"
            #print(out)
            out
          elsif line=~/^s*Early Access Date\s*=/
            line.gsub("Early Access Date","Early_Access_Date")
          elsif scielo_mode and line=~/^\s*author\s*=\s*\{(.+)\}/ # Sorry for this code :(
            parts=$1.split(",")
            #p parts
            authors=(0...(parts.length/2)).map {|v|
              "#{parts[v*2].strip}, #{parts[v*2+1].strip}"
            }.join(" and ")
            out=line.gsub(/^(\s*author\s*=\s*\{)(.+)(\}.*)$/) {|v| "#{$1}#{authors}#{$3}"}
            out
          else
            line
          end
        }.join("\n")
      end
      # Parse a BibTex file
      # @param string [String] BibTex text
      # @param bib_db [String] NOT USED
      # @return BibTex::Reader
      def self.parse(string, bib_db=nil)

        @bib_db=bib_db

        string_fixed=fix_string(string)

        b=BibTeX.parse(string_fixed, :strip => false)
        Reader.new(b)

      end

      def parse_records
        @records=@bb.map {|r| BibTex::Record.create(r)}.find_all {|r| !r.nil?}
      end
    end

    class Writer
      def self.generate(canonical_documents)
        bib = BibTeX::Bibliography.new
        canonical_documents.each do |cd|
          campos=[:title, :abstract, :journal, :year, :volume, :pages,
               :doi, :url, :author, :scopus_id, :wos_id, :scielo_id]

          hash_c=campos.inject({}) {|ac,v|
            ac[v]=cd.send(v)
            ac
          }
          hash_c[:bibtex_type]=:article
          hash_c[:key]="key_#{cd[:id]}_#{cd[:year]}"
          bib << BibTeX::Entry.new(hash_c)

        end

        bib
      end
    end

  end
end

