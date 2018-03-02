require_relative 'reference_methods'
module ReferenceIntegrator

  module CommonRecordAttributes
    attr_accessor :uid
    attr_accessor  :title
    attr_accessor  :abstract
    attr_reader  :authors
    attr_accessor :author

    attr_accessor  :journal
    attr_accessor  :year
    attr_accessor  :volume
    attr_accessor  :pages

    attr_accessor  :type
    attr_accessor  :language
    attr_accessor  :affiliation
    attr_accessor  :doi
    attr_accessor  :keywords
    attr_accessor  :keywords_plus
    attr_accessor  :references_wos
    attr_accessor  :references_scopus
    attr_accessor  :references_crossref
    attr_accessor  :cited
    attr_accessor  :id_wos
    attr_accessor  :id_scopus
    attr_accessor  :url
    attr_accessor  :journal_abbr
  end
end

require_relative 'reference_integrator/bibtex'
require_relative 'reference_integrator/json'
require_relative 'reference_integrator/csv'
