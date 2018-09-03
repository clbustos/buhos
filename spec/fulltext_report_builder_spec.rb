require 'spec_helper'

describe 'Fulltext Report' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/fulltext/html'
    end
    it_should_behave_like 'html standard report'
  end

  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/fulltext/excel_download'
    end
    it_should_behave_like 'excel standard report'
  end



end