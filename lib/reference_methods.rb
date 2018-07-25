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

require_relative 'doi_helpers'
module ReferenceMethods
  include DOIHelpers

  def cite_apa_6
    text_authors=author.split(" and ").map {|v| v.split(",")[0]}

    n_authors=text_authors.length

    if n_authors==1
      "(#{text_authors[0]}, #{year})"
    else
      "(#{text_authors[0...(n_authors-1)].join(", ")} & #{text_authors[n_authors-1]} , #{year})"
    end

  end
  def ref_apa_6_base(text_author)
    "#{text_author} (#{year}). #{title}. #{journal}, #{volume}, #{pages}.#{doi_t}"
  end
  def doi_t
    doi.to_s!="" ? "doi: #{doi}" : ""
  end
  def ref_apa_6
    ref_apa_6_base(author)
  end
  def ref_apa_6_brief
    ref_apa_6_base(authors_apa_6)
  end

  def authors_apa_6
    return "--NA--" if author.nil?
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
  def e_html t
    CGI.escapeHTML(t.to_s)
  end
  def ref_apa_6_brief_html
    doi_t = doi ? "doi: #{a_doi(doi)}" : ""
    "#{e_html(authors_apa_6)} (#{e_html(year)}). #{e_html(title)}. <em>#{e_html(journal)}, #{e_html(volume)}</em>, #{e_html(pages)}. #{doi_t}"
  end
end