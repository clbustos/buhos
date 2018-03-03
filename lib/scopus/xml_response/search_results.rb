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
module Scopus
  module XMLResponse
    
    class Scopus::XMLResponse::Searchresults < XMLResponseGeneric
    def next_page
      @xml.at_xpath("//atom:link[@ref='next']")
    end
    def entries_to_hash
      @xml.xpath("//atom:entry").map {|v|
        title=v.at_xpath("dc:title").nil? ? nil : v.at_xpath("dc:title").text
        journal=v.at_xpath("prism:publicationName").nil? ? nil : v.at_xpath("prism:publicationName").text
        h={
          :scopus_id=>v.at_xpath("dc:identifier").text,
          :title=>title,
          :journal=>journal
        }
        {:creator=>"dc:creator",:doi=>"prism:doi"}.each_pair {|key,xv|
          h[key]=v.at_xpath(xv).text unless v.at_xpath(xv).nil?
        }
        h
      }
    end    
    
  end
end

end