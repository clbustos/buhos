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

require 'digest'


# Reference made on one article to another.
#
# Is the hardest object on the system. All bibliographical system stores
# references on different ways. So, we store the store the test as-is
# and use the sha256 digest as an identifier.
#
# If the text contains a DOI, is very easy to assign the reference to a
# canonical document, but often the reference doesn't have enough information
# to create it. So, we retrieve information from Crossref to create the
# canonical document.

class Reference < Sequel::Model(:bib_references)

  include DOIHelpers
  extend DOIHelpers

  many_to_many :records
  # Retrieve a Reference with a specific text
  # If doesn't exist before, create it
  # @param text reference text, as-is
  # @return a Reference
  def self.get_by_text(text)
    dig=Digest::SHA256.hexdigest text
    Reference[dig]
  end
  # Retrieve a reference using text and doi
  # If doesn't exists before, and param create is true
  # create it
  # @param text
  # @param doi
  # @return Reference or nil
  def self.get_by_text_and_doi(text,doi,create=false)
    dig=Digest::SHA256.hexdigest text
    if doi
      doi=doi_without_http(doi)
      ref=Reference.where(:id=>dig,:doi=>doi).first
    else
      ref=Reference[dig]
    end
    if create and !ref
      Reference.insert(:id=>dig,:text=>text,:doi=>doi)
      ref=Reference[dig]
    end
    ref
  end

  def crossref_query
    CrossrefQuery.generate_query_from_text( self[:text] )
  end

  def search_similars(d=nil, sin_canonico=true)
    begin
      require 'levenshtein-ffi'
    rescue LoadError
      require 'levenshtein'
    end

    canonico_sql= sin_canonico ? " AND canonical_document_id IS NULL ": ""

    distancias=Reference.where(Sequel.lit("id!='#{self[:id]}' #{canonico_sql}")).map {|v|
      {
          :id=>v[:id],
          :canonical_document_id=>v[:canonical_document_id],
          :text=>v[:text],
          :distancia=>Levenshtein.distance(v[:text],self[:text])
      }

    }
    if !d.nil?
      distancias=distancias.find_all {|v| v[:distancia]<=d}
    end
    distancias.sort {|a,b| a[:distancia]<=>b[:distancia]}
  end


  # Retrieve information from Crossref, using doi, and create a canonical document
  #
  def add_doi(doi_n)
    #$log.info("Agregar #{doi_n} a #{self[:id]}")
    status=Result.new

    crossref_doi=CrossrefDoi.procesar_doi(doi_n)

    unless crossref_doi
      status.error("No puedo procesar DOI #{doi_n}")
      return status
    end

    $db.transaction do
      ##$log.info(co)
      if self[:doi]==doi_n
        status.info("Ya agregado DOI para reference #{self[:id]}")
      else
        self.update(:doi=>doi_without_http(doi_n))
        status.success("Se agrega DOI #{doi_n} para reference #{self[:id]}")
      end

      if self[:canonical_document_id].nil?
        can_doc=CanonicalDocument[:doi=>doi_without_http(doi_n)]
        if can_doc
          self.update(:canonical_document_id=>can_doc[:id])
          status.info("Agregado a documento canónico #{can_doc[:id]} ya existente")
        else # No existe el canónico, lo debo crear
          integrator=CrossrefDoi.reference_integrator_json(doi)
          ##$log.info(integrator)
          fields = [:title,:author,:year,:journal, :volume, :pages, :doi, :journal_abbr,:abstract]
          fields_update=fields.inject({}) {|ac,v|
            ac[v]= integrator.send(v); ac;
          }

          # En casos muy raros no está el año. Tengo que reportar error, no más
          if fields_update[:year].nil?
            status.error("El DOI #{doi} no tiene año. Extraño, pero tengo que cancelar misión")
          else
            can_doc_id=CanonicalDocument.insert(fields_update)
            self.update(:canonical_document_id=>can_doc_id)
            status.success("Agregado un nuevo documento canónico #{can_doc_id}: #{integrator.ref_apa_6}")
          end
        end
        $db.after_rollback {
          status=Result.new
          status.error("Rollback en agregar doi para reference #{self[:id]}")
        }
      end
    end

    status
  end


end