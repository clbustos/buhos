# Clase para presentar los abstract en
# html de manera bonita y nanay.
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


