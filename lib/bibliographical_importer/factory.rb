# Copyright (c) 2016-2026, Claudio Bustos Navarrete
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
  class Factory
    attr_reader :object_created
    def self.build(file_body, filename, filetype, result)
      factory = new(file_body, filename, filetype, result)
      factory.process
    end

    def initialize(file_body, filename, filetype, result)
      @file_body=file_body
      @filename=filename
      @filetype=filetype
      @result = result
      @object_created=nil
    end

    def process
      if @file_body.nil?
        error('bibliographic_file_processor.no_file_available')
      else
        case
        when ris?
          parse_ris
        when json?
          parse_json
        when bibtex?
          parse_bibtex
        when pubmed?
          parse_pubmed
        when csv?
          parse_csv
        else
          error('bibliographic_file_processor.no_integrator_for_filetype')
        end
      end
      @object_created
    end


    # --- Verificadores de Formato ---

    def ris?
      @filename =~ /\.ris$/
    end

    def json?
      @filetype == 'application/json' || @filename =~ /\.json$/
    end

    def bibtex?
      ['text/x-bibtex'].include?(@filetype) || @filename =~ /\.(bib|bibtex)$/
    end

    def pubmed?
      ['application/nbib', 'application/x-pubmed'].include?(@filetype) || @filename =~ /\.nbib$/
    end

    def csv?
      @filetype == 'text/csv'
    end

    # --- Lógica de Parsing ---

    def parse_ris
      begin
        @object_created=BibliographicalImporter::Ris::Reader.parse(@file_body)
        success('bibliographic_file_processor.ris_success') # Opcional: mensaje personalizado
      rescue StandardError => e
        @object_created=nil
        error('bibliographic_file_processor.ris_integrator_failed', e)
      end
    end

    def parse_json
      begin
        @object_created=BibliographicalImporter::Json::Reader.parse(@file_body)
        success('bibliographic_file_processor.json_success')
      rescue BibTeX::ParseError => e
        @object_created=nil
        error('bibliographic_file_processor.json_integrator_failed', e)
      end
    end

    def parse_bibtex
      body = @file_body.force_encoding("utf-8")
      body.scrub!("*") unless body.valid_encoding?
      begin
        @object_created=BibliographicalImporter::BibTex::Reader.parse(body)
        success('bibliographic_file_processor.bibtex_success')
      rescue BibTeX::ParseError => e
        @object_created=nil
        error('bibliographic_file_processor.bibtex_integrator_failed', e)
      end
    end

    def parse_pubmed
      begin
        @object_created=BibliographicalImporter::PubmedSummary::Reader.parse(@file_body)
        success('bibliographic_file_processor.pubmed_success')
      rescue PubmedSummary::ParseError => e
        error('bibliographic_file_processor.pubmed_integrator_failed', e)
        @object_created=nil
      end
    end

    def parse_csv
      # Nota: se asume que @search responde a bibliographical_database_name según tu código original
      @object_created=BibliographicalImporter::CSV::Reader.parse(@file_body, @search.bibliographical_database_name)
      success('bibliographic_file_processor.csv_success')
    end


    def success(message_key)
      @result.success(::I18n.t(message_key.to_sym))
    end

    def error(message_key, exception = nil)
      if exception
        detail = "<#{exception.class}> : #{exception.message}"
        @result.error("#{::I18n.t(message_key.to_sym)} : #{detail} ")
      else
        @result.error("#{::I18n.t(message_key.to_sym)}")
      end

    end
  end
end