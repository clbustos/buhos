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
require 'uri'
require 'net/http'
require 'open-uri'
module Scopus
  class Connection
    extend  Scopus::URIRequest
    include Scopus::URIRequest
    attr_reader :key, :error, :error_msg, :xml_response, :raw_xml
    attr_accessor :use_proxy
    attr_accessor :proxy_host, :proxy_post, :proxy_user, :proxy_pass
  def initialize(key, opts={})
    @key=key
    @use_proxy=false
    @error=false
    @error_msg=nil
    if opts[:proxy_host]
      @use_proxy=true
      @proxy_host=opts[:proxy_host]
      @proxy_port=opts[:proxy_port]
      @proxy_user=opts[:proxy_user]
      @proxy_pass=opts[:proxy_pass]
    end
  end
  def connection
    @connection||=get_connection
  end
  def close
    @connection.close if @connection
  end
  
  # Deprecated. Using open-uri, because was impossible to obtain a sensible way to configure the SSL
  def get_connection
    if @use_proxy
      #proxy = ::Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass)
      http=Net::HTTP.new("api.elsevier.com", nil, @proxy_host, @proxy_port, @proxy_user, @proxy_pass)
    else
      http=Net::HTTP.new("api.elsevier.com")
    end
    http.use_ssl=true
    http.ssl_version = :TLSv1_2
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http

  end

  # Connect to api and start
  def connect_server(uri_string)
    proxy_info= @use_proxy ? ["http://#{@proxy_host}:#{@proxy_port}/", @proxy_user, @proxy_pass] : nil
    begin
      open(uri_string, :proxy_http_basic_authentication => proxy_info) do |io|
        xml=Nokogiri::XML(io.read)
        if xml.xpath("//service-error").length>0
          @error=true
          @error_msg=xml.xpath("//statusText").text
        elsif xml.xpath("//atom:error",'atom'=>'http://www.w3.org/2005/Atom').length>0
          @error=true
          @error_msg=xml.xpath("//atom:error").text
        elsif xml.children.length==0
          @error=true
          @error_msg="Empty_XML"
        else
          @error=false
          @error_msg=nil
        end
        @xml_response=Scopus.process_xml(xml)
      end
    rescue OpenURI::HTTPError=>e
      #$log.info(e.message)
      @error=true
      @error_msg=e.message
    end
    
    
  end
  
  def get_articles_from_uri(uri)
    completo=false
    acumulado=[]
    pagina=1
    while(!completo) do
      puts "pagina:#{pagina}"
      xml_response=connect_server(uri)
      if @error
        break
      else
        acumulado=acumulado+xml_response.entries_to_hash
        next_page=xml_response.next_page
        if next_page
          pagina+=1
          uri=next_page.attribute("href").value
        else
#          puts "completo"
          completo=true
        end
      end  
    end
    acumulado
  end
  
  def get_journal_articles(journal,year=nil)
    uri=get_uri_journal_articles(journal,year)
    completo=false
    acumulado=[]
    while !completo do
      xml_response=connect_server(uri)
      if @error
        break
      else
        acumulado=acumulado+xml_response.entries_to_hash
        next_page=xml_response.next_page
        if next_page
          uri=next_page.attribute("href").value
          #puts "siguiente pagina"
        else
          #puts "completo"
          completo=true
        end
      end  
    end
    acumulado
    end  
  end
end
