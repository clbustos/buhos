require 'spec_helper'
require 'tempfile'

describe 'Import and export decisions' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    sr_for_report
    CanonicalDocument.insert(:id=>2, :title=>"Documento 2", :year=>2020)
    create_record(id:[2], cd_id:[2], search_id:[[1]])
    Decision.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                    :stage=>'screening_title_abstract', :decision=>'yes',
                    :commentary=>'Initial yes')
    Decision.insert(:systematic_review_id=>1, :canonical_document_id=>2, :user_id=>1,
                    :stage=>'screening_title_abstract', :decision=>'no',
                    :commentary=>'Initial no')
    login_admin
  end

  def xlsx_rows(response_body)
    tempfile=Tempfile.new(['decisions_export', '.xlsx'])
    tempfile.binmode
    tempfile.write(response_body)
    tempfile.close

    require 'simple_xlsx_reader'
    SimpleXlsxReader.configuration.auto_slurp = true
    doc=SimpleXlsxReader.open(tempfile.path)
    sheet=doc.sheets.first
    rows=sheet.data.map {|row| sheet.headers.zip(row).to_h}
    tempfile.unlink
    rows
  end

  def build_decisions_xlsx(rows)
    require 'caxlsx'
    tempfile=Tempfile.new(['decisions_import', '.xlsx'])
    tempfile.close

    package=Axlsx::Package.new
    package.workbook.add_worksheet(:name => 'decisions') do |sheet|
      sheet.add_row ["systematic_review_id", "canonical_document_id", "user_id", "stage", "decision", "commentary"]
      rows.each do |row|
        sheet.add_row [
          row[:systematic_review_id],
          row[:canonical_document_id],
          row[:user_id],
          row[:stage],
          row[:decision],
          row[:commentary]
        ]
      end
    end
    package.serialize(tempfile.path)
    tempfile
  end

  context 'when decisions are exported to excel' do
    before(:context) do
      get '/review/1/stage/screening_title_abstract/export_decisions_excel'
      @rows=xlsx_rows(last_response.body)
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.header['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }
    it { expect(last_response.header['Content-Disposition']).to include('decisions_1_screening_title_abstract.xlsx') }

    it 'exports the decisions stored in the database' do
      decisions=@rows.map {|row| [row["canonical_document_id"].to_i, row["decision"], row["commentary"]] }
      expect(decisions).to include([1, 'yes', 'Initial yes'])
      expect(decisions).to include([2, 'no', 'Initial no'])
    end
  end

  context 'when decisions are imported from excel' do
    before(:context) do
      @xlsx=build_decisions_xlsx([
        {
          systematic_review_id: 1,
          canonical_document_id: 1,
          user_id: 1,
          stage: 'screening_title_abstract',
          decision: 'no',
          commentary: 'Updated by import'
        },
        {
          systematic_review_id: 1,
          canonical_document_id: 2,
          user_id: 2,
          stage: 'screening_title_abstract',
          decision: 'yes',
          commentary: 'Inserted by import'
        }
      ])

      uploaded_file=Rack::Test::UploadedFile.new(@xlsx.path, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", true)
      post '/review/import_decisions_excel',
           {systematic_review_id: 1, file: uploaded_file},
           'HTTP_REFERER' => '/review/1/stage/screening_title_abstract/import_export_decisions'
    end

    after(:context) do
      @xlsx.unlink if @xlsx
    end

    it { expect(last_response).to be_redirect }

    it 'updates existing decisions' do
      decision=Decision[:systematic_review_id=>1, :canonical_document_id=>1,
                        :user_id=>1, :stage=>'screening_title_abstract']
      expect(decision[:decision]).to eq('no')
      expect(decision[:commentary]).to eq('Updated by import')
    end

    it 'inserts new decisions' do
      decision=Decision[:systematic_review_id=>1, :canonical_document_id=>2,
                        :user_id=>2, :stage=>'screening_title_abstract']
      expect(decision[:decision]).to eq('yes')
      expect(decision[:commentary]).to eq('Inserted by import')
    end
  end
end
