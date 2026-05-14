require_relative 'spec_helper'

describe BibliographicalImporter::CSV::SearchBuilder do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
  end

  it 'uses the search bibliographic database to parse CSV files' do
    search = Search.create(
      systematic_review_id: 1,
      bibliographic_database_id: bb_by_name_id('refworks'),
      user_id: 1,
      filename: 'refworks.csv',
      filetype: 'text/csv',
      file_body: File.read("#{$base}/spec/fixtures/refworks.csv"),
      search_type: 'bibliographic_file'
    )
    result = Result.new

    reader = described_class.build(search, result)

    expect(result.success?).to be true
    expect(reader.records.length).to eq(97)
    expect(reader[0].type).to eq('refworks')
  end
end
