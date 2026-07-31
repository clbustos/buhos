# Copyright (c) 2016-2026, Claudio Bustos Navarrete
# All rights reserved.

require 'json'
require 'net/http'
require 'nokogiri'
require 'uri'

# Retrieves an abstract from the publisher page resolved by a DOI.
class AbstractFromDoi
  DOI_RESOLVER = 'https://doi.org/'.freeze
  MAX_REDIRECTS = 5
  USER_AGENT = 'Buhos abstract retriever'.freeze

  META_NAMES = %w[
    citation_abstract
    dc.description
    dcterms.abstract
    dcterms.description
    eprints.abstract
    prism.teaser
    og:description
    description
  ].freeze

  ABSTRACT_SELECTORS = [
    '[itemprop="abstract"]',
    'section.abstract',
    'div.abstract',
    'article .abstract',
    '#abstract',
    '[id*="abstract"]',
    '[class*="abstract"]'
  ].freeze

  def initialize(doi)
    @doi = normalize_doi(doi)
  end

  def self.get_abstract_cd(cd_id)
    result=Result.new
    cd=CanonicalDocument[cd_id]
    if cd
      if cd.doi
        afd=AbstractFromDoi.new(cd.doi)

        abstract = afd.get_abstract
        if abstract
          cd.update(abstract: abstract)
          result.success("Document:#{cd_id} #{cd.title}, abstract updated from DOI page")
        else
          result.error("Document:#{cd_id} #{cd.title}, no abstract in DOI page")
        end
      else
        result.error("Document:#{cd_id} #{cd.title}, no DOI")
      end
    else
      result.error("No CD:#{cd_id}")

    end
    result
  end

  def get_abstract
    return nil unless @doi

    response = fetch(URI("#{DOI_RESOLVER}#{URI.encode_www_form_component(@doi)}"))
    return nil unless response.is_a?(Net::HTTPSuccess)

    document = Nokogiri::HTML(response.body)

    clean_abstract(metadata_abstract(document) ||
                   json_ld_abstract(document) ||
                   page_abstract(document))
  rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error,
         URI::InvalidURIError, OpenSSL::SSL::SSLError
    nil
  end

  private

  def normalize_doi(doi)
    value = doi.to_s.strip
    value = value.sub(%r{\Ahttps?://(?:dx\.)?doi\.org/}i, '')
    value = value.sub(/\Adoi:\s*/i, '')
    value.empty? ? nil : value
  end

  def fetch(uri, redirects_left = MAX_REDIRECTS)
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = USER_AGENT
    request['Accept'] = 'text/html,application/xhtml+xml'

    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: uri.scheme == 'https',
                               open_timeout: 10, read_timeout: 20) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPRedirection) && redirects_left.positive?
      location = response['location']
      return response unless location

      return fetch(URI.join(uri.to_s, location), redirects_left - 1)
    end

    response
  end

  def metadata_abstract(document)
    META_NAMES.each do |name|
      node = document.css('meta').find do |meta|
        [meta['name'], meta['property']].compact.any? do |attribute|
          attribute.casecmp?(name)
        end
      end
      content = node && node['content']
      return content unless content.to_s.strip.empty?
    end
    nil
  end

  def json_ld_abstract(document)
    document.css('script[type="application/ld+json"]').each do |node|
      value = abstract_in_json(JSON.parse(node.text))
      return value unless value.to_s.strip.empty?
    rescue JSON::ParserError
      next
    end
    nil
  end

  def abstract_in_json(value)
    case value
    when Array
      value.each do |item|
        found = abstract_in_json(item)
        return found if found
      end
    when Hash
      abstract = value['abstract'] || value['description']
      return abstract if abstract.is_a?(String) && !abstract.strip.empty?

      value.each_value do |item|
        found = abstract_in_json(item)
        return found if found
      end
    end
    nil
  end

  def page_abstract(document)
    ABSTRACT_SELECTORS.each do |selector|
      document.css(selector).each do |node|
        text = node.text
        return text if plausible_abstract?(text)
      end
    end

    heading = document.xpath(
      '//*[self::h1 or self::h2 or self::h3 or self::h4]' \
      '[translate(normalize-space(.), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", ' \
      '"abcdefghijklmnopqrstuvwxyz")="abstract" or ' \
      'translate(normalize-space(.), "ABCDEFGHIJKLMNOPQRSTUVWXYZ", ' \
      '"abcdefghijklmnopqrstuvwxyz")="resumen"]'
    ).first
    sibling = heading && heading.xpath('following-sibling::*[1]').first
    sibling.text if sibling && plausible_abstract?(sibling.text)
  end

  def plausible_abstract?(text)
    clean_abstract(text).to_s.length >= 40
  end

  def clean_abstract(text)
    value = Nokogiri::HTML.fragment(text.to_s).text
    value = value.gsub(
      /\A\s*(?:(?i:abstract|resumen)\s*:\s*|(?i:abstract|resumen)\s+(?=[A-ZÁÉÍÓÚ]))/,
      ''
    )
                 .gsub(/\s+/, ' ').strip
    value.empty? ? nil : value
  end
end
