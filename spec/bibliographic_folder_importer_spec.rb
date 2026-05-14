require_relative 'spec_helper'

describe BibliographicFolderImporter do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
  end

  let(:folder) do
    Dir.mktmpdir('buhos_folder_import').tap do |dir|
      FileUtils.cp(
        File.expand_path('../docs/guide_resources/manual.bib', __dir__),
        File.join(dir, 'generic_manual_1.bib')
      )
      FileUtils.mkdir_p(File.join(dir, 'nested'))
      FileUtils.cp(
        File.expand_path('../docs/guide_resources/manual.bib', __dir__),
        File.join(dir, 'nested', 'generic_manual_2.bib')
      )
      FileUtils.touch(File.join(dir, 'DESCARGAS WOS, EBSCO Y PUBMED.docx'))
    end
  end

  after do
    FileUtils.rm_rf(folder) if folder && Dir.exist?(folder)
  end

  it 'creates one search for each bibliographic file in the folder' do
    importer = described_class.new(folder, systematic_review_id: 1, user_id: 1, date: Date.new(2026, 5, 13)).import

    expect(importer.success?).to be true
    expect(importer.summaries.length).to eq(2)
    expect(Search.count).to eq(2)
    expected_paths = Dir.glob(File.join(folder, '**', '*.{bib,bibtex,csv,json,nbib,ris}')).sort.map {|path| File.expand_path(path) }
    expect(Search.order(:id).map(:description)).to eq(expected_paths)
    expect(Search.order(:id).map(:search_criteria)).to eq(['2026-05-13-001', '2026-05-13-002'])
    expect(Search.order(:id).map {|search| search.bibliographical_database_name }).to eq(['generic', 'generic'])
    expect(Search.order(:id).map(:valid)).to eq([true, true])
    expect(Search.order(:id).map {|search| search.records_dataset.count }).to eq([6, 6])
  end

  it 'fails supported files without a bibliographic database name' do
    Dir.mktmpdir('buhos_folder_import').tap do |dir|
      FileUtils.cp(
        File.expand_path('../docs/guide_resources/manual.bib', __dir__),
        File.join(dir, 'manual.bib')
      )

      importer = described_class.new(dir, systematic_review_id: 1, user_id: 1, date: Date.new(2026, 5, 13)).import

      expect(importer.success?).to be false
      expect(importer.summaries.length).to eq(1)
      expect(importer.summaries.first.search_id).to be_nil
      expect(importer.summaries.first.messages).to include('No bibliographic database name found')
    ensure
      FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
    end
  end
end
