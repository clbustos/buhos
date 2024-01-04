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
module Sinatra
  module Tabs
    class TabsContainer
      def initialize(tabs_ids)
        @tabs_ids=tabs_ids
        @first_tab=true
      end
      def header
        tabs_li=@tabs_ids.map {|v|
          "<li role='presentation' class='#{@tabs_ids.keys.first==v[0] ? 'active':''}'>
<a href='#tab-#{v[0]}' aria-control='tab-#{v[0]}' role='tab' data-toggle='tab'>#{v[1]}</a></li>
"
        }

        "<ul class='nav nav-tabs' role='tablist'>
#{tabs_li.join("\n")}
</ul>
"
      end
      def start_body
        @first_tab=true
        "<div class='tab-content'>"
      end
      def tab(id)
        raise "No id in tabs" if @tabs_ids[id].nil?
        close_prev= @first_tab ? "" : "</div>"

        current_tab="<div role='tabpanel' class='tab-pane #{@first_tab ? 'active':''}' id='tab-#{id}'>"
        @first_tab=false
        "#{close_prev}\n#{current_tab}"
      end

      def end_body
        "</div>\n</div>"
      end
    end
    module Helpers
      def  get_tabs(tabs:)
        TabsContainer.new(tabs)
      end
    end
    def self.registered(app)
      app.helpers Tabs::Helpers
    end
  end
register Tabs
end