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
    "<a target='_black' href='#{url_doi_}'>#{url_doi_}</a>"
  end

  def doi_sin_http(doi)
    doi.gsub(/http.+doi.org\// ,"")
  end
end