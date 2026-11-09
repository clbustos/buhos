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
      {'yes'=>0, 'no'=>3, 'undecided'=>0, 'ND'=>0}
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
      expect(groups.map {|group| group['data-reviewers'].to_i}).to eq([3, 2, 1, 0])
      expect(groups.map {|group| group.css('tbody tr').length}).to eq([1, 1, 2, 1])
      groups.each do |group|
        expect(group.css('.badge.alert-danger[role="alert"]').any?).to eq(group['data-reviewers'].to_i < minimum)
      end
      expect(html.css('.decision-statistics-group a[href*="/resolution/yes"]').length).to eq(5)
    end
  end

  after(:all) do
    close_sqlite
  end
end
