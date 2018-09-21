require 'spec_helper'

# TODO: Check references on bibtex
describe 'Generate crossref references on admin stage' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    info={:doi=>"10.14257/ijseia.2016.10.1.16"}
    CanonicalDocument[1].update(info)
    Record[1].update(info)
    # Just to not query crossref on this
    $db[:crossref_dois].insert(:doi=>'10.14257/ijseia.2016.10.1.16',:json=>read_fixture("crossref_ex_1.json"))
    login_admin
  end

  context "when '/review/:rev_id/stage/:stage/generate_crossref_references' is retrieved" do
    let(:page) {get '/review/1/stage/screening_title_abstract/generate_crossref_references'; last_response}
    it "should be a redirect" do
      expect(page).to be_ok
    end
    it "should include url for stream" do
      expect(page.body).to include("/review/1/stage/screening_title_abstract/generate_crossref_references_stream")
    end
  end

  context "when '/review/:rev_id/stage/:stage/generate_crossref_references_stream' is retrieved" do
    before(:context) do
      get '/review/1/stage/screening_title_abstract/generate_crossref_references_stream'
    end
    it "should send correct content_type" do

      expect(last_response.header['Content-Type']).to eq('text/event-stream;charset=utf-8')
    end

    it "should send correct information" do
      expect(last_response.body).to include('id: 0')
      expect(last_response.body).to match /Processing.+Title 1/
      expect(last_response.body).to match /No references found/

    end

  end



end