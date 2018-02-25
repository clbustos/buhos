require_relative "../spec_helper"


module ScopusMixin
  def load_arr(file)
    rev_xml=File.dirname(File.expand_path(__FILE__))+"/fixtures/#{file}"
    xml=File.open(rev_xml) { |f|
      Nokogiri::XML(f)
    }
  Scopus.process_xml(xml)
  end
end


RSpec.configure { |c| c.include ScopusMixin }