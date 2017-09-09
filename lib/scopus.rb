require 'rubygems'
require 'bundler/setup'


require "nokogiri"
# Clase para cargar Scopus
module Scopus
  # Factory method
    def self.process_xml(xml)
      xml=Nokogiri::XML(xml) if xml.is_a? String
      name=xml.children[0].name.gsub("-","").capitalize
      Scopus::XMLResponse.const_get(name.to_sym).new(xml)
    end
    
    def self.entries_to_csv(entries,csv_file)
      require 'csv'
      d=Date.today.to_s      
      header=["scopus_id","title","journal","creator","doi","date"]
      CSV.open(csv_file,"wb") {|csv|
        csv << header
        entries.each {|e|
          csv << [e[:scopus_id],e[:title],e[:journal], e[:creator],e[:doi],d]
        }
      }
    end
    
end

require_relative "scopus/uri_request"  
require_relative "scopus/connection"
require_relative "scopus/xml_response"
  
  
