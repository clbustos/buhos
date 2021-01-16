# Copyright (c) 2016-2021, Claudio Bustos Navarrete
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

end