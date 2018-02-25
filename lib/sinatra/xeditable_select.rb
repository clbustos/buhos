module Sinatra
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
      def initialize(values, url,html_class)
        process_values(values)
        @url_data=url
        @html_class=html_class
        @title=::I18n.t(:Select_an_option)
        @method="put"
        @active=true
      end
      def process_values(x)
        @values={}
        x.each_pair {|key,val|
          @values[key.to_s]=val
        }
      end
      def javascript
        source=values.map {|v|
          "{value:'#{v[0]}', text:'#{v[1].gsub("'","")}'}"
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

      def html(id,value)

        value_value = value.nil? ? nil_value.to_s : value.to_s
        value_text = value.nil? ? values[nil_value.to_s] : values[value.to_s]
        return value_text if !active
        "<a href='#' class='#{html_class}' id='select-#{html_class}-#{id}' data-value='#{value_value}' data-pk='#{id}'>#{value_text}</a>"
      end
    end
    module Helpers
      def  get_xeditable_select(values,url,html_class)
        Select.new(values,url,html_class)
      end
      def get_xeditable_select_bool(url,html_class)
        values={0 =>::I18n.t("No"),
                1 => ::I18n.t("Yes")
        }
        Select.new(values,url,html_class)
      end
    end

    def self.registered(app)
      app.helpers Xeditable_Select::Helpers
    end
  end
  register Xeditable_Select
end