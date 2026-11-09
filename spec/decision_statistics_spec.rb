require_relative 'spec_helper'

describe 'Decision statistics by reviewer count' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    create_stage_dataset
    login_admin
  end

  let(:patterns) do
    [
      {'yes'=>0, 'no'=>0, 'undecided'=>0, 'ND'=>4},
      {'yes'=>1, 'no'=>0, 'undecided'=>0, 'ND'=>3},
      {'yes'=>0, 'no'=>1, 'undecided'=>0, 'ND'=>0},
      {'yes'=>1, 'no'=>0, 'undecided'=>1, 'ND'=>2},
      {'yes'=>0, 'no'=>3, 'undecided'=>0, 'ND'=>0},
      {'yes'=>2, 'no'=>0, 'undecided'=>0, 'ND'=>1},
      {'yes'=>0, 'no'=>2, 'undecided'=>0, 'ND'=>0},
      {'yes'=>1, 'no'=>1, 'undecided'=>0, 'ND'=>0},
      {'yes'=>2, 'no'=>1, 'undecided'=>1, 'ND'=>0},
      {'yes'=>1, 'no'=>2, 'undecided'=>1, 'ND'=>0},
      {'yes'=>2, 'no'=>2, 'undecided'=>0, 'ND'=>0}
    ]
  end

  {
    'screening_title_abstract'=>[:expected_reviewers_screening, 1],
    'screening_references'=>[:expected_reviewers_snowball, 2],
    'review_full_text'=>[:expected_reviewers_full_text, 3],
    'extract_information'=>[:expected_reviewers_extraction, 4]
  }.each do |stage, (field, minimum)|
    it "groups patterns in descending order and flags the configured minimum for #{stage}" do
      SystematicReview[1].update(field=>minimum)
      allow_any_instance_of(AnalysisSystematicReview).to receive(:decisions_pattern).with(stage).and_return(patterns.to_h {|pattern| [pattern, 1]})
      resolutions=patterns.to_h {|pattern| [pattern, {'yes'=>0, 'no'=>0, Resolution::NO_RESOLUTION=>1}]}
      allow_any_instance_of(AnalysisSystematicReview).to receive(:resolutions_f_pattern_decision).with(stage).and_return(resolutions)
      get "/review/1/administration/#{stage}"
      expect(last_response).to be_ok
      html=Nokogiri::HTML(last_response.body)
      groups=html.css('.decision-statistics-group')
      expected_groups={1=>[0], 2=>[2, 1, 0], 3=>[4, 2, 1, 0], 4=>[4, 3, 2, 1, 0]}
      expected_counts={1=>[1], 2=>[2, 2, 1], 3=>[3, 4, 2, 1], 4=>[3, 1, 4, 2, 1]}
      expect(groups.map {|group| group['data-reviewers'].to_i}).to eq(expected_groups[minimum])
      expect(groups.map {|group| group.css('tbody tr').length}).to eq(expected_counts[minimum])
      strict=html.css('.decision-statistics-strict tbody tr')
      expect(strict.length).to eq({1=>10, 2=>6, 3=>1, 4=>0}[minimum])
      if minimum==2
        expect(strict.map {|row| row.css('td').first(3).map {|cell| cell.text.to_i}}).to eq([[2, 2, 0], [2, 1, 1], [1, 2, 1], [0, 3, 0], [2, 0, 0], [0, 2, 0]])
      end
      groups.each do |group|
        expect(group.css('.badge.alert-danger[role="alert"]').any?).to eq(group['data-reviewers'].to_i < minimum)
      end
      expect(html.css('#decision_statistics ~ div a[href*="/resolution/yes"]').length).to eq(11)
    end
  end

  after(:all) do
    close_sqlite
  end
end
