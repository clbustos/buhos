require 'spec_helper'
require_relative '../lib/buhos/review_document_validator'

describe Buhos::ReviewDocumentValidator do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
  end

  before(:each) do
    configure_empty_database
    create_sr
    create_search(id: [1], systematic_review_id: 1)
    CanonicalDocument.insert(id: 1, title: nil, abstract: nil, author: 'Author one', year: 2020, doi: '10.1/crossref')
    CanonicalDocument.insert(id: 2, title: 'Semantic title', abstract: '', author: 'Author two', year: 2021, doi: '10.1/semantic')
    CanonicalDocument.insert(id: 3, title: 'No abstract', abstract: nil, author: 'Author three', year: 2022)
    create_record(id: [1, 2, 3], cd_id: [1, 2, 3], search_id: [[1], [1], [1]])

    CrossrefDoi.insert(
      doi: '10.1/crossref',
      json: [{
        'message' => {
          'title' => ['Crossref title'],
          'abstract' => 'Crossref abstract'
        }
      }].to_json
    )
    Semantic_Scholar_Paper.insert(
      id: 's2id',
      doi: '10.1/semantic',
      json: {
        'paperId' => 's2id',
        'title' => 'Semantic title',
        'abstract' => 'Semantic abstract'
      }.to_json
    )
  end

  it 'completes missing title and abstract from external service caches' do
    log_file = Tempfile.new('review-document-validator').path
    validator = described_class.new(SystematicReview[1], log_file: log_file).validate

    expect(CanonicalDocument[1].title).to eq('Crossref title')
    expect(CanonicalDocument[1].abstract).to eq('Crossref abstract')
    expect(CanonicalDocument[2].abstract).to eq('Semantic abstract')
    expect(validator.stats[:total]).to eq(3)
    expect(validator.stats[:valid]).to eq(2)
    expect(validator.stats[:invalid]).to eq(1)
    expect(validator.invalid_documents).to include(id: 3, missing: [:abstract])
    expect(File.read(log_file)).to include('Summary total=3 valid=2 invalid=1')
  ensure
    FileUtils.rm_f(log_file) if log_file
  end
end
