require 'spec_helper'

shared_examples "pdf file" do
  let(:filesize) {File.size(filepath)}
  it "should response be ok" do expect(last_response).to be_ok end
  it "should content type be application/pdf" do expect(last_response.header['Content-Type']).to eq('application/pdf') end
  it "should content length be correct" do expect(last_response.header['Content-Length']).to eq(filesize.to_s) end

end

describe 'Search made by files:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    SystematicReview.insert(:id=>1,:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin
  end
  
  def check_gs
    !gs_available or ENV['TEST_TRAVIS'] or is_windows?
  end
  def delete_files
    $db["DELETE FROM files"]
  end
  def delete_canonical_documents
    $db["DELETE FROM canonical_documents"]
  end
  def delete_searches
    $db["DELETE FROM searches"]
  end
  def delete_records
    $db["DELETE FROM records_searches"]
    $db["DELETE FROM records"]
  end

  def filepaths
    filenames=["2010_Kiritchenko_et_al_ExaCT_automatic_extraction_of_clinical_trial_characteristics_from_journal_publications.pdf",
               "2016_Howard et al._SWIFT-Review A text-mining workbench for systematic review.pdf"]
    paths=filenames.map {|filename| File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")}
    paths
  end


  context 'when upload a file using /review/process_files' do
    before(:context) do
      delete_files
      delete_canonical_documents
      delete_searches
      delete_records
      uploaded_file_1=Rack::Test::UploadedFile.new(filepaths[0], "application/pdf", true)
      uploaded_file_2=Rack::Test::UploadedFile.new(filepaths[1], "application/pdf", true)
      post '/review/search/add_files', systematic_review_id:sr_by_name_id('Test Review'), files:[uploaded_file_1, uploaded_file_2]
    end
    after(:context) do
      delete_files
      delete_canonical_documents
      delete_searches
      delete_records
    end
    let(:file1) {IFile[1]}
    let(:file2) {IFile[2]}

    let(:app_helpers) {Class.new {extend Buhos::Helpers}}
    it "should response will be redirect" do
      expect(last_response).to be_redirect
    end
    it "should create two file objects" do

      expect(file1).to be_truthy
      expect(file2).to be_truthy
    end
    it "should create file objects with correct mime type" do
      expect(file1[:filetype]).to eq("application/pdf")
      expect(file2[:filetype]).to eq("application/pdf")
    end

    it "should create files on correct directory" do
      path="#{app_helpers.dir_files}/#{file1[:file_path]}"
      expect(File.exist? path).to be true
      path="#{app_helpers.dir_files}/#{file2[:file_path]}"
      expect(File.exist? path).to be true
    end
    it "should create files of correct size" do
      path="#{app_helpers.dir_files}/#{file1[:file_path]}"
      expect(File.size(path)).to eq(File.size(filepaths[0]))
      path="#{app_helpers.dir_files}/#{file2[:file_path]}"
      expect(File.size(path)).to eq(File.size(filepaths[1]))
    end
  end

end