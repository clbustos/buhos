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
#

require_relative "xeditable_abstract"
#
module Sinatra
  # Provide Javascript and html for a X-Editable checkbox list
  #
  # Example
  #     xselect=get_xeditable_checkbox({a:'a',b:'b', c:'c', d:'d'}, "/path/to/action/", '.my_custom_checkbox')
  # On javascript section, you include
  #     xselect.javascript
  # On html side, you include
  #     xselect.html(resource_id, [:a, :b])
  module Xeditable_Checkbox
    class Checkbox < XeditableAbstract
      def xeditable_type
        'checklist'
      end

      def html(id, value)
        value_value = value.nil? ? "": value.join(",")
        value_text = (value.nil? or value.length==0) ? ::I18n::t(:empty) : value.map{|v|  @values[v.to_s]}.join(", ")
        return value_text if !active
        "<a href='#' class='#{html_class}' id='select-#{html_class}-#{id}' data-value='#{value_value}' data-pk='#{id}'>#{value_text}</a>"
      end
    end
    module Helpers
      def get_xeditable_checkbox(values, url, html_class)
        Checkbox.new(values, url, html_class)
      end
    end

    def self.registered(app)
      app.helpers Xeditable_Checkbox::Helpers
    end
  end
  register Xeditable_Checkbox
end