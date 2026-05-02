require 'spec_helper'

describe 'Record complete information' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr
    create_search(id:[1], systematic_review_id:1)

    CanonicalDocument.insert(id:1, title:'Incomplete one', author:'Author one', abstract:nil, year:2020)
    CanonicalDocument.insert(id:2, title:'Incomplete two', author:'Author two', abstract:'', year:2021)
    CanonicalDocument.insert(id:3, title:'Complete one', author:'Author three', abstract:'Abstract', year:2022)
    create_record(id:[1,2,3], cd_id:[1,2,3], search_id:[1,1,1])

    login_admin
  end

  after(:all) do
    FileUtils.rm_rf(@temp) if @temp.is_a?(String)
  end

  it 'shows a fresh link back to records and the next invalid record' do
    get '/review/1/search/1/record/1/complete_information'

    expect(last_response).to be_ok
    expect(last_response.body).to include('/review/1/searches/records?_ts=')
    expect(last_response.body).to include('/review/1/search/1/record/2/complete_information?_ts=')
  end

  it 'does not show a next invalid record when there is none' do
    get '/review/1/search/1/record/2/complete_information'

    expect(last_response).to be_ok
    expect(last_response.body).not_to include('/review/1/search/1/record/3/complete_information')
  end
end
