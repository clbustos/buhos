require_relative 'spec_helper'
describe 'Search importing bibliographic file:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end

  def filepath
    filename="manual.bib"
    File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
  end
  let(:search) {Search[1]}
  let(:filesize) {File.size(filepath)}
  let(:sr_id) {sr_by_name_id('Test Review')}
  let(:bb_id) {bb_by_name_id('generic')}


  def update_search
    uploaded_file=Rack::Test::UploadedFile.new(filepath, "text/x-bibtex",true)
    post '/search/update', {search_id:'', file:uploaded_file, systematic_review_id: sr_by_name_id('Test Review') , bibliographic_database_id:bb_by_name_id('generic'), source:'informal_search', date_creation:'2018-01-01', search_type:"bibliographic_file"}
  end



  context 'when create a search based on a bibliographic file by form' do
    before(:context) do
      update_search
    end

    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "should response redirects to review dashboard" do
      expect(last_response.header['Location']).to eq("http://example.org/review/#{sr_id}/dashboard")
    end
    it "should search be created on dataset" do
      expect(search).to be_truthy
    end
    it "should search contains correct file name" do
      expect(search[:filename]).to eq('manual.bib')
    end
    it "should search bibliographic database will be generic" do
      expect(search[:bibliographic_database_id]).to eq(bb_id)
    end
    it "should search date will be 2018-01-01" do
      expect(search[:date_creation]).to eq(Date.new(2018,01,01))
    end

    # Remember that sqlite sends to ruby a ASCII-8BIT
    it "should search contains correct file content" do
      expect(search[:file_body].force_encoding('UTF-8')).to eq(File.binread(filepath).force_encoding('UTF-8'))
    end


  end


  context "when review searches is accessed" do
    before(:context) do
      update_search
    end
    let(:response) {get "/review/#{sr_by_name_id('Test Review')}/searches"}
    it { expect(response).to be_ok}
    it "should include a row for new search" do
      expect(response.body).to include("id='row-search-1'")
    end

  end



  context "when search view is accesed" do
    before(:context) do
      update_search
    end
    let(:response) {get '/search/1'}
    it { expect(response).to be_ok}
    it "should include the bibliographic database name " do
      expect(response.body).to include("generic")
    end
    it "should include a link to file" do
      expect(response.body).to include("/search/1/file/download")
    end
  end

  context "when edit form search is acceded" do
    before(:context) do
      update_search
    end
    let(:response) {get '/search/1/edit'}
    it { expect(response).to be_ok}
    it "should include the bibliographic database name " do
      expect(response.body).to include("generic")
    end
    it "should include a link to file" do
      expect(response.body).to include("/search/1/file/download")
    end
  end



  context "when search file is downloaded" do
    before(:context) do
      update_search
    end
    let(:response) {get '/search/1/file/download'}

    it { expect(response).to be_ok}
    it "should response be ok" do expect(response).to be_ok end
    it "should content type be text/x-bibtex" do expect(response.header['Content-Type']).to include('text/x-bibtex') end
    it "should content length be correct" do expect(response.header['Content-Length']).to eq(filesize.to_s) end
    it "should filename will be correct" do expect(response.header['Content-Disposition']).to eq('attachment; filename=manual.bib') end
  end

  context 'when process the search using batch form' do

    before(:context) do
      searches_id=[1]
      post '/searches/update_batch', {sr_id:1, search:1, searches:searches_id, action:'process', url_back:'URL_BACK'}
    end
    it "response should be redirect" do
      #$log.info(last_response)
      expect(last_response).to be_redirect
    end
    it "should response redirects to 'url_back' param" do
      expect(last_response.header['Location']).to eq("http://example.org/URL_BACK")
    end
  end

  context "records when search is already processed" do

    let(:expected_titles) do
      [
          "SLuRp : A Tool to Help Large Complex Systematic Literature Reviews Deliver Valid and Rigorous Results",
          "SWIFT-Review: A text-mining workbench for systematic review",
          "ExaCT: automatic extraction of clinical trial characteristics from journal publications",
          "RevManHAL: Towards automatic text generation in systematic reviews",
          "GAPscreener: An automatic tool for screening human genetic association literature in PubMed using the support vector machine technique",
          "Effectiveness and efficiency of search methods in systematic reviews of complex evidence: Audit of primary sources"
      ].sort
    end
    before(:context) do
      searches_id=[1]
      update_search

      post '/searches/update_batch', {search:1,searches:searches_id, action:'process', url_back:'URL_BACK'}
    end
    let(:records) {Search[1].records_dataset }
    it "should be 6" do
      expect(records.count).to eq(6)
    end
    it "should have correct titles " do
      actual_titles=records.map(:title).sort
      expect(actual_titles).to eq(expected_titles)
    end
    it "should have correct bibliographic db assigned" do
      expect(records.map(:bibliographic_database_id).uniq).to eq([bb_id])
    end
    context "and records view is accesed" do
      before(:context) do
        get '/search/1/records'
      end
      it {expect(last_response).to be_ok}
      it "should contain all titles" do
        expected_titles.each do |title|
          expect(last_response.body).to include title
        end
      end
    end

  end
  context 'when validate the search with direct link' do
    before(:context) do
      update_search

      get '/search/1/validate'
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "search should be validated" do
      expect(search[:valid]).to be true
    end
  end

  context 'when invalidate the search with direct link' do
    before(:context) do
      update_search
      get '/search/1/invalidate'
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "search should be invalidated" do
      expect(search[:valid]).to be false
    end
  end
  context "when try to add DOI for each reference" do
    before(:context) do
      update_search

      get '/search/1/references/search_doi'
    end
    it "response should be redirect" do
      expect(last_response).to be_redirect
    end
    it "session message should be" do
      expect(last_request.env['rack.session']["messages"].find {|v| v[0]==I18n::t(:Search_add_doi_references, count:0)}).to be_truthy
    end
  end
end


