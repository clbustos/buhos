require 'spec_helper'

describe 'Fulltext Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    sr_for_report
    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/fulltext/html'
    end
    it_should_behave_like 'html standard report'
  end

  it "treats regular expression metacharacters in inline codes as literal text" do
    inline_code = "supplemented with research results showing less problem and delinquent behaviour among girls from SS school in comparison to girls from coed schools). (...) These findings [mentioned in square brackets"
    $db[:analysis_sr_1].where(:user_id=>1, :canonical_document_id=>1).
      update(:field_1=>"Paragraph with [#{inline_code}] and trailing text.")

    get '/review/1/report/fulltext/html'

    expect(last_response).to be_ok
    expect(last_response.body).to include(inline_code)
  end

  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/fulltext/excel_download'
    end
    it_should_behave_like 'excel standard report'
  end



end
