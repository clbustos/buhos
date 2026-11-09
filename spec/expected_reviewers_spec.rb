require_relative 'spec_helper'

describe 'Expected reviewers configuration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    login_admin
    sr_for_report
  end

  let(:fields) { SystematicReview::EXPECTED_REVIEWER_FIELDS }

  it 'defaults every stage to two reviewers and displays the fields in their own tab' do
    expect(fields.map { |field| SystematicReview[1][field] }).to eq([2, 2, 2, 2])
    get '/review/new'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    fields.each do |field|
      input=html.at_css("#sr-reviewers input[name='#{field}']")
      expect(input['value']).to eq('2')
    end
  end

  it 'saves independent values and describes each stage in the technical record' do
    values=fields.zip([1, 3, 4, 5]).to_h
    post '/review/update', values.merge(:review_id=>'1')
    expect(last_response).to be_redirect
    expect(fields.map { |field| SystematicReview[1][field] }).to eq([1, 3, 4, 5])
    get '/review/1'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    values.each do |field, value|
      expect(html.at_css("span[name='#{field}']").text).to eq(value.to_s)
      expect(last_response.body).to include(I18n.t("#{field}_description"))
    end
    get '/review/1/edit'
    expect(last_response).to be_ok
    html=Nokogiri::HTML(last_response.body)
    values.each do |field, value|
      expect(html.at_css("#sr-reviewers input[name='#{field}']")['value']).to eq(value.to_s)
    end
  end

  it 'rejects invalid counts without changing the review' do
    previous=SystematicReview[1].values
    ['0', '-1', '1.5', '', 'abc'].each do |value|
      post '/review/update', :review_id=>'1', fields.first=>value
      expect(last_response.status).to eq(400)
      expect(SystematicReview[1].values).to eq(previous)
    end
  end

  after(:all) do
    sr_for_report_down
    close_sqlite
  end
end
