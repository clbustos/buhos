require 'spec_helper'

describe 'Process Report with resolutions' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/process/html'
      #puts last_response.body
    end
    it_should_behave_like 'html standard report'

  end

  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/process/excel_download'
    end
    it_should_behave_like 'excel standard report'

  end



end

describe 'Process Report without resolutions' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    $db[:resolutions].delete
    $db[:decisions].delete
    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/process/html'
      #puts last_response.body
    end
    it_should_behave_like 'html standard report'

  end

  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/process/excel_download'
    end
    it_should_behave_like 'excel standard report'

  end
end

describe 'Process Report without searches' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    $db[:resolutions].delete
    $db[:decisions].delete
    $db[:records_searches].delete


    login_admin
  end
  context "when html is retrieved" do
    before(:context) do
      get '/review/1/report/process/html'
      #puts last_response.body
    end
    it_should_behave_like 'html standard report'

  end

  context "when full text report excel is downloaded" do
    before(:context) do
      get '/review/1/report/process/excel_download'
    end
    it_should_behave_like 'excel standard report'

  end
end