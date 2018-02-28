module DOIHelpers
  def url_doi(doi)
    if doi=~/http/
      doi
    else
      "http://doi.org/#{doi}"
    end
  end
  def a_doi(doi)
    url_doi_=url_doi(doi)
    "<a target='_blank' href='#{url_doi_}'>#{url_doi_}</a>"
  end

  def doi_without_http(doi)
    return nil if doi.nil?
    doi.gsub(/http.+doi.org\// ,"")
  end


  def find_doi(texto)
    if texto=~/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/
      return $1
    else
      return nil
    end
  end
end