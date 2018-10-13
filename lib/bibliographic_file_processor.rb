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

# encoding: utf-8
#

# Searches based on bibliography files, like bibtex, should be processed, to obtain all necessary information
# This class retrieves records and references, using the file attached to a search.
#
# Main methods are {.process_file} and {.process_canonical_documents}. Only if file
# can be processed, continues with the processing of canonical documents.
#
# In pseudocode, the structure is
#   process_file()
#     .get_integrator()
#       for each reference in integrator
#         .process_reference()
#       add integrator references as records on search
#   process_canonical_documents
#    for each record on search
#      create a canonical document
#
class BibliographicFileProcessor
  attr_reader :search
  attr_reader :result
  attr_reader :error
  attr_reader :canonical_document_processed
  def initialize(search)
    @search = search
    @result = Result.new
    @error = nil
    @canonical_document_processed=false
    if process_file

      process_canonical_documents
    end
  end

  def log_error(message, extra_info=nil)
    @result.error("#{::I18n::t(message)}: ID #{@search[:id]} #{extra_info}")
  end

  def log_success(message, extra_info=nil)
    @result.success("#{::I18n::t(message)}:ID #{@search[:id]} #{extra_info}")
  end


  def process_file
    begin
      integrator = get_integrator
      return false unless integrator
    rescue BibTeX::ParseError => e
      log_error('bibliographic_file_processor.error_parsing_file', e.message)
      @error="#{I18n::t('bibliographic_file_processor.error_parsing_file')} #{e.message}"
      return false
    end

    #$log.info(integrator)
    correct = true
    $db.transaction do
      bb = BibliographicDatabase.name_a_id_h
      ref_ids = []
      ref_i = 0
      integrator.each do |reference|

        ref_i += 1
        if reference.nil?
          @result.error(::I18n::t('bibliographic_file_processor.error_on_reference', i: ref_i))
          correct = false
          next
        end
        #$log.info(Encoding::default_external)
        #$log.info(reference.to_s.encoding)
        bb_id = bb[reference.type.to_s]
        #$log.info(reference.type.to_s )
        if bb_id.nil?
          @result.error(::I18n::t('bibliographic_file_processor.no_unique_id_for_integrator', integrator: bb_id))
          correct = false
          break
        end

        reg_o=process_reference(bb_id, reference)
        ref_ids.push(reg_o[:id])
      end
      @search.update_records(ref_ids)
    end
    if correct
      log_success('bibliographic_file_processor.Search_process_file_successfully')
    else
      @error=t('bibliographic_file_processor.Search_process_file_error')
      log_error('bibliographic_file_processor.Search_process_file_error')
    end

    true
  end

  def process_canonical_documents

    bb = BibliographicDatabase.id_a_name_h
    $db.transaction(:rollback => :reraise) do

      @search.records.each do |record|
        fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]

        fields_update = create_hash_update(fields, record)
        registro_base_id = "#{bb[record.bibliographic_database_id]}_id".to_sym
        if record[:canonical_document_id].nil?
          can_doc = nil
          # Verifiquemos si existe doi
          if record[:doi].to_s =~ /10\./
            can_doc = CanonicalDocument[:doi => record[:doi]]
          end

          if can_doc.nil?
            fields_to_update=fields_update.merge({registro_base_id => record[:uid]})
            fields_to_update[:year]=0 if fields_to_update[:year].nil? # A VERY UGLY FIX. Maybe we just update canonical document to allow year=nil
            can_doc_id = CanonicalDocument.insert(fields_to_update)
            can_doc = CanonicalDocument[:id => can_doc_id]
          end
          record.update(:canonical_document_id => can_doc[:id])
        else


          update_cd_fields(fields, record, registro_base_id)

        end
      end
    end # db.transaction
    @canonical_document_processed=true
    log_success('bibliographic_file_processor.Search_canonical_documents_successfully', "#{I18n::t(:Count_canonical_documents)} : #{@search.records.count}" )
  end

  def create_hash_update(fields, record)
    fields.inject({}) {|ac, v|
      ac[v] = record.send(v); ac;
    }
  end

  # Factory method to retrieve a integrator.
  #
  # For BibTex, ReferenceIntegrator::BibTex::Reader takes control and decides how to process using BibTeX fields
  # For CSV, we need to send the bibliograpic database.
  # @see ReferenceIntegrator::BibTex
  # @see ReferenceIntegrator::CSV

  def get_integrator
    if @search[:file_body].nil?
      log_error('bibliographic_file_processor.no_file_available')
      false
    elsif @search[:filetype] == 'text/x-bibtex' or @search[:filename] =~ /\.bib$/
      BibliographicalImporter::BibTex::Reader.parse(@search[:file_body])
    elsif @search[:filetype] == 'text/csv' # Por trabajar
      #$log.info(bibliographical_database_name)
      BibliographicalImporter::CSV::Reader.parse(@search[:file_body], @search.bibliographical_database_name)
    else
      log_error('bibliographic_file_processor.no_integrator_for_filetype')
      false
    end
  end

  def get_cit_refs_ids(cited_references)
    cit_refs_ids = []
    cited_references.each do |cr|
      dig = Digest::SHA256.hexdigest cr
      cit_refs_ids.push(dig)
      ref_o = Reference[dig]
      unless ref_o
        Reference.insert(:id => dig, :text => cr)
      end
    end
    cit_refs_ids.uniq!
    cit_refs_ids
  end

  def update_cd_fields(fields, registro, registro_base_id)
    can_doc = CanonicalDocument[registro[:canonical_document_id]]
    # Verificamos si tenemos una nueva información que antes no estaba
    raise Buhos::NoCdIdError, registro[:canonical_document_id] unless can_doc
    fields_new_info = fields.find_all {|v| (can_doc[v].nil? or can_doc[v].to_s == '') and !(registro[v].nil? or registro[v].to_s == '')}
    ##$log.info(fields.map {|v| registro[v]})
    unless fields_new_info.nil?
      fields_update_2 = create_hash_update(fields_new_info, registro)
      can_doc.update(fields_update_2)
    end

    can_doc.update(registro_base_id => registro[:uid])
  end


  private :get_cit_refs_ids
  private :update_cd_fields

  def process_reference(bb_id, reference)
    reg_o = Record[:uid => reference.uid, :bibliographic_database_id => bb_id]

    if reg_o.nil?
      reg_o_id = Record.insert(:uid => reference.uid, :bibliographic_database_id => bb_id)
      reg_o = Record[reg_o_id]
    end


    #attr_accessor :uid,:title, :abstract, :author, :journal, :year, :volume, :pages,
    #              :type, :language, :affiliation, :doi, :keywords,:keywords_plus,
    #              :references_wos, :references_scopus, :cited, :id_wos,
    #              :id_scopus,:url, :journal_abbr

    fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]

    fields_update = fields.find_all {|v| reg_o[:field].nil? and reference.send(v) != ''}.inject({}) {|ac, v|
      ac[v] = reference.send(v); ac;
    }

    reg_o.update(fields_update)

    # Procesar references
    cited_references = reference.cited_references
    unless cited_references.nil?
      cit_refs_ids = get_cit_refs_ids(cited_references)
      reg_o.update_references(cit_refs_ids)
    end
    reg_o
  end

end
