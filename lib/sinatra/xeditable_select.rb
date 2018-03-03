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
#
#
module Sinatra
  # Provide Javascript and html for a X-Editable select box
  #
  # Example
  #     xselect=get_xeditable_select({a:'a',b:'b', c:'c', d:'d'}, "/path/to/action/", '.my_custom_selects')
  # On javascript section, you include
  #     xselect.javascript
  # On html side, you include
  #     xselect.html(resource_id, :a)
  module Xeditable_Select
    class Select
      # Hash of key, values to put on select
      attr_reader :values
      # Url to send information to
      attr_reader :url_data
      # Class of the text that links to the editable select. Should be unique for every type of select.
      attr_reader :html_class
      # Title of dialog
      attr_accessor :title
      # Value that represent the nil option. If the value incorpored on html method
      # is nil, it will be replaced with this
      attr_accessor :nil_value
      # Method to send the request. By default, is put
      attr_accessor :method
      # By default, true. Could be set to false conditional on permission
      attr_accessor :active

      def initialize(values, url, html_class)
        process_values(values)
        @url_data = url
        @html_class = html_class
        @title = ::I18n.t(:Select_an_option)
        @nil_value=::I18n.t(:empty)
        @method = "put"
        @active = true
      end

      def process_values(x)
        @values = {}
        x.each_pair {|key, val|
          @values[key.to_s] = val
        }
      end

      def javascript
        source = values.map {|v|
          "{value:'#{v[0]}', text:'#{v[1].gsub("'", "")}'}"
        }.join(",\n")

        "
$(document).ready(function () {
$('.#{html_class}').editable({
type:'select',
title:'#{title}',
mode:'inline',
ajaxOptions: {
    type: '#{method}'
},
url:'#{url_data}',
source: [#{source}]
});
});
"
      end

      def html(id, value)
        value_value = value.nil? ? nil_value.to_s : value.to_s
        value_text = value.nil? ? values[nil_value.to_s] : values[value.to_s]
        return value_text if !active
        "<a href='#' class='#{html_class}' id='select-#{html_class}-#{id}' data-value='#{value_value}' data-pk='#{id}'>#{value_text}</a>"
      end
    end
    module Helpers
      def get_xeditable_select(values, url, html_class)
        Select.new(values, url, html_class)
      end

      def get_xeditable_select_bool(url, html_class)
        values = {0 => ::I18n.t("No"),
                  1 => ::I18n.t("Yes")
        }
        Select.new(values, url, html_class)
      end
    end

    def self.registered(app)
      app.helpers Xeditable_Select::Helpers
    end
  end
  register Xeditable_Select
end