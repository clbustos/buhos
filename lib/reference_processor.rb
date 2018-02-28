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
    if @reference.texto =~/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/
      doi=check_doi($1)
      update_fields={:doi=>doi}
      cd=Canonico_Documento[:doi => doi]
      update_fields[:canonico_documento_id]=cd[:id] if cd
      @reference.update(update_fields)
      @result.success(I18n::t(:Reference_with_new_doi, reference_id:@reference[:id], doi:doi))
      true
    else
      false
    end
  end

end