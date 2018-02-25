require_relative 'scopus'

class ScopusRemote
  attr_reader :scopus
  attr_reader :error

  def initialize
    @scopus=Scopus::Connection.new(ENV["SCOPUS_KEY"], :proxy_host => ENV["PROXY_HOST"], :proxy_port => ENV["PROXY_PORT"], :proxy_user => ENV["PROXY_USER"], :proxy_pass => ENV["PROXY_PASS"])
    @error=nil
  end

  # @param id Id to retrieve. By default, doi
  # @param type type of identifier. By default, doi, but could it be eid
  def xml_abstract_by_id(id, type="doi")
    uri_abstract=@scopus.get_uri_abstract(CGI.escapeElement(id), type=type)
    xml=@scopus.connect_server(uri_abstract)
    if @scopus.error
      #$log.info(@scopus.error_msg)
      @error=@scopus.error_msg
      false
    else
      xml
    end
  end
end