require_relative 'spec_helper'
describe 'Search importing big bibliographic file:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  def filepath
    File.expand_path("#{File.dirname(__FILE__)}/../spec/fixtures/scopus_wrong_2.bib")
  end

  let(:search) {Search[1]}
  let(:sr_id) {sr_by_name_id('Test Review')}
  let(:filesize) {File.size(filepath)}

  context 'when create a search based on a big file' do
    before(:context) do

      uploaded_file=Rack::Test::UploadedFile.new(   filepath , "text/x-bibtex",true)
      post '/search/update', {search_id:'',
                              file:uploaded_file,
                              systematic_review_id: sr_by_name_id('Test Review') ,
                              bibliographic_database_id:bb_by_name_id('scopus'),
                              source:'informal_search',
                              date_creation:'2018-01-01', search_type:"bibliographic_file"}
    end

    it "should search be created on dataset" do
      expect(search).to be_truthy
    end

    it "should search contains correct file name" do
      expect(search[:filename]).to eq('scopus_wrong_2.bib')
    end
    it "should search contains a big file_body" do
      expect(search[:file_body].length).to  eq(filesize)
    end

  end
end