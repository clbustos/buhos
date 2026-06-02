require_relative 'spec_helper'

describe Buhos::DuplicateAnalysis do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
  end

  before do
    $db[:canonical_documents].delete
  end

  it 'detects exact metadata duplicates' do
    CanonicalDocument.insert(id: 1, title: 'A duplicate title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-2')
    CanonicalDocument.insert(id: 2, title: 'A duplicate title', author: 'Other Author', year: 2020, journal: 'Journal', pages: '1-2')
    CanonicalDocument.insert(id: 3, title: 'A different title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-2')

    analysis = described_class.new(CanonicalDocument.dataset)

    expect(analysis.by_metadata).to eq([[1, 2]])
  end

  it 'detects very similar metadata duplicates using author field' do
    CanonicalDocument.insert(id: 1, title: 'A duplicate title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-2')
    CanonicalDocument.insert(id: 2, title: 'A duplicate title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-3')

    analysis = described_class.new(CanonicalDocument.dataset)

    expect(analysis.by_metadata).to eq([[1, 2]])
  end

  it 'does not report records with different doi values as metadata duplicates' do
    CanonicalDocument.insert(id: 1, title: 'A duplicate title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-2', doi: '10.1/a')
    CanonicalDocument.insert(id: 2, title: 'A duplicate title', author: 'Author', year: 2020, journal: 'Journal', pages: '1-2', doi: '10.1/b')

    analysis = described_class.new(CanonicalDocument.dataset)

    expect(analysis.by_metadata).to eq([])
  end
end
