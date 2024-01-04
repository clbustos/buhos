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

require 'elsevier_api'

class ScopusRemote
  attr_reader :scopus
  attr_reader :error

  def initialize
    @scopus=ElsevierApi::Connection.new(ENV["SCOPUS_KEY"], :proxy_host => ENV["PROXY_HOST"], :proxy_port => ENV["PROXY_PORT"], :proxy_user => ENV["PROXY_USER"], :proxy_pass => ENV["PROXY_PASS"])
    @error=nil
  end

  # @param id Id to retrieve. By default, doi
  # @param type type of identifier. By default, doi, but could it be eid
  def xml_abstract_by_id(id, type="doi")
      uri_abstract=@scopus.get_uri_abstract(CGI.escapeElement(id), type=type, {})
      xml=@scopus.retrieve_response(uri_abstract)
      if @scopus.error
        #$log.info(@scopus.error_msg)
        @error=@scopus.error_msg
        false
      else
        xml
      end
      
  end
end