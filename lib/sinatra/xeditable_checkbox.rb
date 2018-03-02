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
    class Checkbox
      # Hash of key, values to put on checkbox list
      attr_reader :values
      # Url to send information to
      attr_reader :url_data
      # Class of the text that links to the editable select. Should be unique for every type of select.
      attr_reader :html_class
      # Title of dialog
      attr_accessor :title
      # Method to send the request. By default, is put
      attr_accessor :method
      # By default, true. Could be set to false conditional on permission
      attr_accessor :active

      def initialize(values, url, html_class)
        process_values(values)
        @url_data = url
        @html_class = html_class
        @title = ::I18n.t(:Select_an_option)
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
type:'checklist',
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