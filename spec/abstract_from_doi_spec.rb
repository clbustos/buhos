require 'spec_helper'
require_relative '../lib/abstract_from_doi'

describe AbstractFromDoi do
  let(:retriever) { described_class.new('https://doi.org/10.1234/example') }

  def success_response(body)
    Net::HTTPOK.new('1.1', '200', 'OK').tap do |response|
      response.instance_variable_set(:@read, true)
      response.body = body
    end
  end

  it 'retrieves an abstract from citation metadata' do
    html = <<~HTML
      <html><head>
        <meta name="citation_abstract" content="This is a sufficiently long abstract obtained from metadata.">
      </head></html>
    HTML
    allow(retriever).to receive(:fetch).and_return(success_response(html))

    expect(retriever.get_abstract).to eq(
      'This is a sufficiently long abstract obtained from metadata.'
    )
  end

  it 'retrieves an abstract from JSON-LD' do
    html = <<~HTML
      <script type="application/ld+json">
        {"@type":"ScholarlyArticle","abstract":"Abstract from structured page data."}
      </script>
    HTML
    allow(retriever).to receive(:fetch).and_return(success_response(html))

    expect(retriever.get_abstract).to eq('Abstract from structured page data.')
  end

  it 'retrieves an abstract from visible page text' do
    html = <<~HTML
      <section class="abstract">
        <h2>Abstract</h2>
        <p>This visible abstract is long enough to be considered useful page text.</p>
      </section>
    HTML
    allow(retriever).to receive(:fetch).and_return(success_response(html))

    expect(retriever.get_abstract).to eq(
      'This visible abstract is long enough to be considered useful page text.'
    )
  end

  it 'returns nil when the page contains no abstract' do
    allow(retriever).to receive(:fetch).and_return(
      success_response('<html><body><p>No useful data.</p></body></html>')
    )

    expect(retriever.get_abstract).to be_nil
  end

  it 'returns nil for an empty DOI' do
    expect(described_class.new(nil).get_abstract).to be_nil
  end
end
