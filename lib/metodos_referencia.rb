require_relative 'doi_helpers'
module MetodosReferencia
  include DOIHelpers
  def ref_apa_6
    ##$log.info("#{self.class} #{author}")
    doi_t = doi ? "doi: #{doi}" : ""
    "#{author} (#{year}). #{title}. #{journal}, #{volume}, #{pages}.#{doi_t}"
  end
  def authors_apa_6
    authors=author.split(" and ").map {|v| v.strip}
    if authors.length>7
      author_ref=(authors[0..5]+["..."]+[authors.last]).join(", ")

    elsif authors.length>1
      author_ref=authors[0..(authors.length-2)].join(", ")+", & "+authors.last
    else
      author_ref=author
    end
    author_ref
  end
  def ref_apa_6_breve
    doi_t = doi ? "doi: #{doi}" : ""
    "#{authors_apa_6} (#{year}). #{title}. #{journal}, #{volume}, #{pages}.#{doi_t}"

  end
  def ref_apa_6_breve_html
    doi_t = doi ? "doi: #{a_doi(doi)}" : ""
    CGI.escapeHTML("#{authors_apa_6} (#{year}). #{title}. #{journal}, #{volume}, #{pages}.")+doi_t

  end
end