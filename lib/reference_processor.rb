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

# Class that add doi and canonical documents to references
# Later, we could add PMID and EID support
class ReferenceProcessor

  include DOIHelpers
  extend DOIHelpers
  attr_reader :reference, :result
  def initialize(reference)
    @reference=reference
    @result=Result.new
  end
  # Change doi to correct format
  # WOS references have several problems with DOI
  def check_doi(doi)
    if doi and doi=~/(10.+?);(unstructured|author|volume)/
      doi=$1
    end
    doi
  end
  # If reference text have a doi inside, add that to object
  # assign a canonical document if exists
  def process_doi
    if @reference.text =~/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/
      doi=check_doi($1)
      update_fields={:doi=>doi}
      cd=CanonicalDocument[:doi => doi]
      update_fields[:canonical_document_id]=cd[:id] if cd
      @reference.update(update_fields)
      @result.success(I18n::t(:Reference_with_new_doi, reference_id:@reference[:id], doi:doi))
      true
    else
      false
    end
  end
  # Assign several references to canonical documents
  # If the reference already have a canonical_document, skip
  # If can retrieve doi, assign to canonical_document using that doi
  # If canonical_document not exists for a doi, create the canonical_document and assign the doi
  # If not doi is present, try a search on crossref. Is score > 100, create the canonical_document
  # If not, just create the title
  # @return Result
  def self.assign_to_canonical_document(references)
    result=Result.new
    $db.transaction do
      references.each do |ref|
        if ref[:doi].nil?
          rp=ReferenceProcessor.new(ref)
          rp.process_doi
        end

        if !ref[:canonical_document_id].nil?
          result.info("Reference #{ref[:text]} have already a canonical_document_assigned")
        elsif !ref[:doi].nil?
          result.add_result(add_doi(ref))
        else # no doi, no canonical document
          query=CrossrefQuery.generate_query_from_text( ref[:text])
          items=query["message"]["items"]
          $log.info(query)
          if items.length>0 and items[0]["score"]>100
            doi=doi_without_http(items[0]["DOI"])
            ref.update(:doi=>doi)
            result.add_result(add_doi(ref))
          else
            result.warning("Can't assign doi to reference #{ref[:text]}")
          end

        end
      end
    end
    result
  end

  def self.add_doi(ref)
    result =Result.new
    doi=ref[:doi]
    cd = CanonicalDocument[:doi => doi]
    if cd
      ref.update(:canonical_document_id => cd[:id])
      result.success("Reference #{ref[:text]} assigned to canonical document #{cd[:id]}")
    else
      ri_json = CrossrefDoi.reference_integrator_json(ref[:doi])
      if ri_json
        fields = [:title, :author, :year, :journal, :volume, :pages, :doi, :journal_abbr, :abstract]
        update_data = fields.inject({}) do |ac, v|
          ac[v] = ri_json.send(v) unless ri_json.send(v).nil?
          ac
        end
        if update_data.keys.length > 0
          update_data[:year]=0 if update_data[:year].nil?
          cd_id = CanonicalDocument.insert(update_data)
          ref.update(:canonical_document_id => cd_id)
          result.success("Canonical document #{cd_id} created and reference #{ref[:text]} assigned to it")
        end
      else
        result.error("Can't process doi #{ref[:doi]} for reference #{ref[:text]}")
      end
    end
    result
  end

end