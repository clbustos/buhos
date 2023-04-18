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


require_relative 'reference_methods'


# Namespace to import different formats of bibliographic reference
# Every Importer should follow this API
# * {AbstractRecord}: A representation of a record. Could be an article, a book or another type of resource
# * {AbstractReader}: Class that process record on a given format. Could parse a string, or read a file
# * {AbstractWriter}: Class that exports a list of canonical documents on a give format.
module BibliographicalImporter

  # The Reader shouldn't be instantiated directly, but using {.parse} or {.open}
  # Reader include {Enumerable}, so each traverse along the records
  module AbstractReader
    include Enumerable
    # Parse a file
    # @param filename [String] or [IO]
    def self.open(filename)
      raise "Should read a filename"
    end

    # Parse a string
    # @param string [String] to parse
    # @param bib_db [String] Bibliographic database name. Could affect the processing of text. See  {BibliographicDatabase}
    def self.parse(string, bib_db=nil)
      raise "Should write a file"
    end
  end

  # The Writer shouldn't be instantiated directly, but using {.generate} or a derivate class
  # Thats allows flexibility on the export
  module AbstractWriter
    # Generate the file format, based on an Array of {CanonicalDocument}
    # @param [Array] of {CanonicalDocument}
    # @return
    def self.generate(canonical_documents)
       raise "should generate a file"
    end
  end



  # List of common attributes that a {BibliographicImporter::AbstractRecord}  should have
  module CommonRecordAttributes
    # Unique identifier for the record. IT SHOULD BE IMPLEMENTED
    # On CVS, for example, SHA256 of string 'authors-year-title', is used
    attr_accessor :uid
    # Title of record
    attr_accessor  :title
    # Abstract for the record
    attr_accessor  :abstract
    # String that list all authors
    attr_accessor :author
    # Array of authors. Usually, {author} should be processed to obtain this
    attr_reader  :authors
    # Journal, is applicable
    attr_accessor  :journal
    # Year of publishing
    attr_accessor  :year
    attr_accessor  :volume
    attr_accessor  :pages

    attr_accessor  :type
    attr_accessor  :language
    attr_accessor  :affiliation
    attr_accessor  :doi

    attr_accessor  :keywords
    attr_accessor  :keywords_plus
    #References, as listed by WOS
    attr_accessor  :references_wos
    #References, as listed by Scopus
    attr_accessor  :references_scopus
    #References, as listed by Crossref

    attr_accessor  :references_crossref
    attr_accessor  :cited

    attr_accessor  :url
    attr_accessor  :journal_abbr

    attr_accessor :wos_id
    attr_accessor :scopus_id
    attr_accessor :ebscohost_id
    attr_accessor :scielo_id
    attr_accessor :refworks_id
    attr_accessor :pubmed_id
  end


  # The BibliographicalImporter::AbstractRecord shouldn't be instantited directly, but using {.create} methods
  # Usually, the {ReaderAbstract} class provides and already preprocessed record and record just adapt it
  # to {CommonRecordAttributes} interface. So, works like an Adapter
  module AbstractRecord
    include CommonRecordAttributes
    def self.create
      raise "Should be implemented"
    end
  end

end

require_relative 'bibliographical_importer/bibtex'
require_relative 'bibliographical_importer/json'
require_relative 'bibliographical_importer/json_api_crossref'
require_relative 'bibliographical_importer/csv'
require_relative 'bibliographical_importer/pmc_efetch_xml'
require_relative 'bibliographical_importer/pubmed_summary'
