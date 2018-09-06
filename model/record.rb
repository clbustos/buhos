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

require_relative 'canonical_document'

class Record < Sequel::Model
  include ReferenceMethods
  include DOIHelpers
  many_to_one :canonical_document, :class=>CanonicalDocument
  # Obtener una Query Crossref. Se utiliza el APA 6
  def crossref_query
    CrossrefQuery.generate_query_from_text( ref_apa_6 )
  end
  # Asigna un doi automaticamente desde crossref
  # y verifica que el DOI del canónico calce
  def add_doi_automatic
    result=Result.new
    $log.info(self)
    if self.doi.nil? or self.doi==""
      $log.info(self)
      query=crossref_query

      if query.length>0 and query[0]["score"]>100
        result.add_result(add_doi(query[0]["doi"]))
        result.success(I18n.t(:Assigned_DOI_to_record, record_id: self[:id], author: self[:author], title: self[:title], doi:query[0]["doi"] ))
      else
        result.warning(I18n.t(:DOI_not_assigned_to_record, record_id: self[:id], author: self[:author], title: self[:title] ))
      end
    elsif canonical_document.doi.nil?
        result.add_result(add_doi(self[:doi]))
    elsif canonical_document.doi!=self[:doi]
        result.warning("DOI para canonico #{canonical_document[:doi]}  y reference #{self[:id]} -> #{self[:doi]} difieren")
    else
      result.info(I18n::t("record.doi_already_added_to", record_title: self[:title]))
    end
    result
  end

  # @param references_id ID de references que deberían estar acá
  def update_references(references_id, modo=:aditivo)
    result=Result.new
    cit_ref_yap=$db["SELECT reference_id FROM records_references WHERE record_id=?", self[:id]].map {|v| v[:reference_id]}

    cit_rep_por_ingresar = (references_id- cit_ref_yap).uniq
    cit_rep_por_borrar = (cit_ref_yap - references_id).uniq
    $db.transaction do
      if cit_rep_por_ingresar.length>0
        $db[:records_references].multi_insert(cit_rep_por_ingresar.map {|v| {:reference_id => v, :record_id => self[:id]}})
        result.info( ::I18n.t(:Added_references_to_record, :record_id=>self[:id], :count_references=>cit_rep_por_ingresar.length))
      end

      if cit_rep_por_borrar.length>0 and modo==:sincronia
        $db[:records_references].where(:record_id => self[:id], :reference_id => cit_rep_por_borrar).delete
        result.info( ::I18n.t(:Deleted_references_to_record, :record_id=>self[:id], :count_references=>cit_rep_por_borrar.length))
      end
    end
    result

  end

  # Update record and canonical document using crossref information
  def update_info_using_crossref
    result=Result.new
    ri_json=CrossrefDoi.reference_integrator_json(self[:doi])
    if ri_json
      fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]
      update_data=fields.inject({}) do |ac,v|
        ac[v]=ri_json.send(v)  unless ri_json.send(v).nil?
        ac
      end

      self.update(update_data) unless update_data.keys.length==0
    end
    result
  end
  def references_automatic_crossref
    result=Result.new
    ri_json=CrossrefDoi.reference_integrator_json(self[:doi])
    if ri_json and ri_json.references
      ref_ids=[]
      ri_json.references.each do |reference|
        doi=reference.doi
        text=reference.to_s
        ref=Reference.get_by_text_and_doi(text,doi,true)
        if doi
          cd=CanonicalDocument.where(:doi=>doi_without_http(doi)).first
          ref.update(:canonical_document_id=>cd[:id]) if cd and ref.canonical_document_id.nil?
        end
        ref_ids.push(ref[:id])
      end
      result.add_result(update_references(ref_ids,:aditivo))
      result.success(I18n::t("record.references_for_crossref_processed", n:ri_json.references.count))
    else
      result.info(I18n::t("record.no_references_on_crossref"))
    end

    result
  end

  # @param doi
  # @return Result
  def add_doi(doi)
    status=Result.new
    crossref_doi=CrossrefDoi.process_doi(doi)

    unless crossref_doi
      status.error(I18n::t("record.cant_process_doi", doi:doi))
      return status
    end

    ##$log.info(co)
    if self[:doi]==doi
      status.info(I18n::t("record.already_added_doi", doi:doi, record_id: self.id))
    else
      self.update(:doi=>doi_without_http(doi))
      status.success("Se agrega DOI #{doi} para registro #{self[:id]}")
    end

    # Verificamos si el canónico calza con el original
    can_doc_original=CanonicalDocument[self[:canonical_document_id]]
    can_doc_doi=CanonicalDocument.where(:doi=>doi_without_http(doi)).first
    if can_doc_original[:doi]==doi_without_http(doi)
      status.info(I18n::t("record.already_added_doi_on_cd", doi:doi, cd_title:can_doc_original[:title]))
    elsif !can_doc_doi # No hay ningún doc previo con este problema
      can_doc_original.update(:doi=>doi_without_http(doi))
      status.success(I18n::t("record.assigned_doi_to_cd",doi:doi, cd_title:can_doc_original[:title]))
    else  # Ok, tenemos un problema. No lo podemos resolver ahora, sólo podemos avisar en el canónico
      can_doc_original.update(:doi=>doi_without_http(doi),:duplicated=>can_doc_doi[:id])
      status.warning("Se agregó a canónico #{can_doc_original[:doi]} el DOI, pero existe un duplicado (#{can_doc_doi[:id]}). Revisar")
    end
    status
  end

  def references_id
    $db["SELECT reference_id FROM records_references rr WHERE record_id=?", self[:id]].select_map(:reference_id)

  end

  def references
    Reference.where(:id => references_id)
  end

end
