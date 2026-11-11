require_relative 'spec_helper'

describe 'Administration table totals' do
  include RSpecMixin

  before do
    configure_empty_database
    create_stage_dataset
    login_admin
  end

  %w[screening_title_abstract screening_references review_full_text extract_information].each do |stage|
    it "summarizes resolutions and totals each pattern table for #{stage}" do
      get "/review/1/administration/#{stage}"
      expect(last_response).to be_ok
      html=Nokogiri::HTML(last_response.body)
      resolutions=AnalysisSystematicReview.new(SystematicReview[1]).resolution_by_cd(stage).values
      summary=html.at_css('table.stage-resolution-summary')
      expect(summary.css('tbody td').map {|cell| cell.text.to_i}).to eq([
        resolutions.count('yes'), resolutions.count('no'),
        resolutions.count {|value| !%w[yes no].include?(value)}, resolutions.length
      ])
      expect(html.css('table').first).to eq(summary)
      tables=html.css('.decision-statistics-group table, .decision-statistics-strict table')
      expect(tables).not_to be_empty
      tables.each do |table|
        totals=Array.new(8, 0)
        table.css('tbody tr').each do |row|
          values=row.css('td').first(8).map {|cell| cell.text.to_i}
          4.times {|column| totals[column]+=values[column]*values[4]}
          (4..7).each {|column| totals[column]+=values[column]}
        end
        expect(table.css('tfoot td').map {|cell| cell.text.to_i}).to eq(totals)
      end
      user_table=html.at_css('table.user-decision-statistics')
      if user_table
        rows=user_table.css('tbody tr').map {|row| row.css('td').drop(1).map {|cell| cell.text.to_i}}
        expect(user_table.css('tfoot td').drop(1).map {|cell| cell.text.to_i}).to eq(rows.transpose.map(&:sum))
      end
    end
  end
end
