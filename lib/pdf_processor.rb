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

require 'pdf-reader'
require_relative "doi_helpers"

# Class to process PDF information.
# Processing to add PDF to a systematic review is performed by PdfFileProcessor

class PdfProcessor


  include DOIHelpers
  include Buhos::Helpers
  attr_reader :reader
  def initialize(path)
    @path=path
    @reader=PDF::Reader.new(@path)
    @pages={}
  end


  def page(i)
    @pages[i]||=reader.pages[i]
  end


  def keywords
    page_for_keywords=reader.pages[0..1].index {|page| page.text=~/Keywords?\s*:/}
    #$log.info(page_for_keywords)
    return nil if page_for_keywords.nil?

    page(page_for_keywords).text=~/Keywords?\s*:(.+)/

    $1.split(/[,;.]/).map {|v| v.lstrip.chomp}

  end

  def abstract

    # First, we locate the page on which is located the abstract
    page_for_abstract=reader.pages[0..1].index {|page| page.text=~/Abstract/}

    return nil if page_for_abstract.nil?

    mode=:pre
    abstract_lines=[]
    empty_lines=0

    page(page_for_abstract).text.each_line do |r|
      line=r.chomp.lstrip
      if mode==:pre and line=~/Abstract/ # We must include other languages
        mode=:abstract
        # There is more information on this line?

        if (line_wo_abstract=(line.gsub(/(?:Abstract):?/,"")).lstrip)!=""
          abstract_lines.push(line_wo_abstract)
        end

      elsif mode==:abstract
        if line=="" or line=~/Keywords/
          empty_lines+=1
          break if empty_lines>2
        else
          empty_lines=0
          abstract_lines.push(line)
          abstract_lines.push("\n") if line[-1]=="."
        end
      end

    end
    abstract_lines.join("")
  end



  def title
    reader.info[:Title]
  end

  def author
    nil
  end

  def get_doi

    doi = nil
    info = reader.info
    #$log.info(info)
    if info[:doi]
      doi = info[:doi]
    elsif info[:Subject]
      doi = find_doi(protect_encoding(info[:Subject]))
    end

    if doi.nil?
      primera_pagina = reader.pages[0].text
      doi = find_doi(primera_pagina)
    end
    doi
  end
end