class ReferenceProcessor
  attr_reader :reference, :result
  def initialize(reference)
    @reference=reference
    @result=Result.new
  end
  # WOS references have several problems with DOI
  def check_doi
    if @reference.doi and @reference.doi=~/(10.+?);(unstructured|author|volume)/
      @reference.doi=$1
    end
  end
  def process_doi
    if @reference.texto =~/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/
      doi=$1
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