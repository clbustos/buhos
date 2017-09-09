module Scopus
  module XMLResponse
    class XMLResponseGeneric
    attr_reader :xml
    def initialize(xml)
      @xml=xml
      process()
    end
    # Just put anything you want here
    def process
    end
    def process_path(x, path)
      node=x.at_xpath(path)
      (node.nil?) ? nil : node.text
    end
    end

  end
end

require_relative "xml_response/abstract_retrieval_response"
require_relative "xml_response/search_results"
require_relative "xml_response/service_error"
require_relative "xml_response/abstract_citation_response"
require_relative "xml_response/author_retrieval_response"
require_relative "xml_response/author_retrieval_response_list"
