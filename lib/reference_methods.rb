# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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

  def raw_key_value
    [:uid, :authors_apa_6, :year, :title, :journal, :volume, :pages, :doi, :wos_id, :pubmed_id, :scopus_id, :scielo_id].map {|k|
      v=self.send(k)
      "<strong>#{k}:</strong>#{v.nil? ? "<span class='no_value'>#{I18n::t(:no_value)}</span>" : v}"}.join("; ")
  end
  def cite_apa_6
    "(#{authors_apa_6}, #{year})"
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

  def author_ref_apa_6(x)
    x=x.to_s.strip
    if x.include? "," # we assume surname, first-name
      parts=x.split(",").map(&:strip)
      return "" if parts.length==0
      surname=parts[0]
      if parts[1].nil?
        "#{surname}"
      else
        names=parts[1].split(' ').map(&:strip)
        initials=names.map{|v| "#{v[0]}."}.join("")
        "#{surname}, #{initials}"
      end
    else # we assume names in order
      parts=x.split(' ').map(&:strip)
      if parts.length==1
        x
      else
        surname=parts.pop
        initials=parts.map{|v| "#{v[0]}."}.join("")
        "#{surname}, #{initials}"
      end
    end
  end
  def authors_apa_6
    return "--NA--" if author.nil?

    authors=author.split(" and ").map {|v| author_ref_apa_6(v)}
    return '--NA--' if authors.all? {|v| v==""}
    if authors.length>7
      author_ref=(authors[0..4]+["..."]+[authors.last]).join(", ")

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