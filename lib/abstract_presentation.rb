# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

# Present abstract, highlighting keywords
class AbstractPresentation
  attr_accessor :text
  attr_accessor :keywords
  attr_accessor :tag_keyword
  attr_accessor :class_keyword

  def initialize(text=nil)
    @text=text
    @keywords=nil
    @tag_keyword="strong"
    @class_keyword=nil
  end

  def begin_tag
    class_out= @class_keyword ? " class='#{@class_keyword}'" : ""
    "<#{@tag_keyword}#{class_out}>"
  end

  def end_tag
    "</#{@tag_keyword}>"
  end

  def html_with_keywords
    return "" if text.nil?
    out=CGI.escapeHTML(text).to_s.gsub("\n", "<br/>")
    if @keywords
      regexps=Regexp.new '('+@keywords.join("|")+')'
      out=out.gsub(regexps, "#{begin_tag}\\1#{end_tag}")
    end
    out
  end
end


