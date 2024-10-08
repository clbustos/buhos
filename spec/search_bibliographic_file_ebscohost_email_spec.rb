require_relative 'spec_helper'
describe 'EBSCOhost Bibliographic File Import Process inside Search context:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  def filepath
    File.expand_path("#{File.dirname(__FILE__)}/../spec/fixtures/ebscohost_wrong_1.bib")
  end

  let(:search) {Search[1]}
  let(:sr_id) {sr_by_name_id('Test Review')}
  let(:filesize) {File.size(filepath)}
  let(:bb_id) {bb_by_name_id('ebscohost')}

  def update_search
    uploaded_file=Rack::Test::UploadedFile.new(   filepath , "text/x-bibtex",true)
    post '/search/update', {search_id:'', file:uploaded_file,
                            systematic_review_id: sr_by_name_id('Test Review') ,
                            bibliographic_database_id:bb_by_name_id('ebscohost'),
                            source:'informal_search', date_creation:'2018-01-01',
                            search_type:"bibliographic_file"}
  end

  context 'Creating a search from an EBSCOhost BibTeX email file' do
    before(:context) do
      update_search
    end

    it "creates the search in the dataset" do
      expect(search).to be_truthy
    end

    it "saves the correct file name in the search" do
      expect(search[:filename]).to eq('ebscohost_wrong_1.bib')
    end
    it "stores the file with the correct size in the search" do
      expect(search[:file_body].length).to  eq(filesize)
    end
  end


  context "Processing search records after importing the file" do


    before(:context) do
      searches_id=[1]
      update_search

      post '/searches/update_batch', {search:1,searches:searches_id, action:'process', url_back:'URL_BACK'}
    end
    let(:records) {Search[1].records_dataset }
    it "should be 199" do
      expect(records.count).to eq(199)
    end
    context "and records view is accesed" do
      before(:context) do
        get '/search/1/records'
      end
      it {expect(last_response).to be_ok}
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
end