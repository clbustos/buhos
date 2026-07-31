require 'spec_helper'
require_relative '../model/semantic_scholar_paper'
require_relative '../lib/semantic_scholar'

describe Semantic_Scholar_Paper do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end

  before(:each) do
    configure_empty_database
    CanonicalDocument.insert(id: 1,
                             title: 'Cached paper',
                             abstract: nil,
                             author: 'Author one',
                             year: 2024,
                             doi: '10.1/cached',
                             semantic_scholar_id: 's2-cached')
    Semantic_Scholar_Paper.insert(
      id: 's2-cached',
      doi: '10.1/cached',
      json: {
        'paperId' => 's2-cached',
        'title' => 'Cached paper',
        'abstract' => 'Cached Semantic Scholar abstract'
      }.to_json
    )
  end

  it 'completes a missing abstract from cached Semantic Scholar data' do
    result = described_class.get_abstract_cd(1)

    expect(result.success?).to be true
    expect(CanonicalDocument[1].abstract).to eq('Cached Semantic Scholar abstract')
  end
end
