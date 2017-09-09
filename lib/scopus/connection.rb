require 'uri'
require 'net/http'
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
  
  
  def get_connection
    if @use_proxy
      proxy = ::Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass)
      proxy.start("api.elsevier.com")
    else
      Net::HTTP.new("api.elsevier.com")
    end
  end
  # Connect to api and start 
  def connect_server(uri_string)
    uri = URI(uri_string)
    req = Net::HTTP::Get.new(uri.request_uri)
    req['Accept']='application/xml'
    res = connection.request(req)
    xml=Nokogiri::XML(res.body)
    if xml.xpath("//service-error").length>0
      @error=true
      @error_msg=xml.xpath("//statusText").text
    elsif xml.xpath("//atom:error",'atom'=>'http://www.w3.org/2005/Atom').length>0
      @error=true
      @error_msg=xml.xpath("//atom:error").text
    else
      @error=false
      @error_msg=nil
    end
    @xml_response=Scopus.process_xml(xml)
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
          puts "completo"
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
          puts "siguiente pagina"
        else
          puts "completo"
          completo=true
        end
      end  
    end
    acumulado
    end  
  end
end
