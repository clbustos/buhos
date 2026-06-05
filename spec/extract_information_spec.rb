require_relative 'spec_helper'


describe 'Buhos extraction of data' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    #AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
    #                    :stage=>"review_full_text")

    sr_for_report
    CanonicalDocument.insert(:id=>2, :title=>"Better software required", :year=>2020)
    CanonicalDocument[1].update(:title=>"Better software required", :abstract=>"[RevMan]")
    SrField.insert(:systematic_review_id=>1, :order=>1, :name=>"stages", :description=>"Stages",
                   :type=>"textarea")
    SrField.insert(:systematic_review_id=>1, :order=>2, :name=>"features", :description=>"Features",
                   :type=>"textarea")
    SrField.insert(:systematic_review_id=>1, :order=>3, :name=>"tools", :description=>"Tools",
                   :type=>"textarea")

    SrField.update_table(SystematicReview[1])
    sr=SystematicReview[1]

        AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"screening_title_abstract")
        AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"review_full_text")
        AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"extract_information")
    $db[:analysis_sr_1].where(:user_id=>1, :canonical_document_id=>1).update(
                          :tools=>"[RevMan]",
                          :stages=>"[RevMan]",
                          :features=>"[RevMan]")
    login_admin

  end
  context 'when admin request form for a included document (1)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}
    it {expect(response_request).to be_ok}
    it {expect(response_request.body).to include "Better software required"}
    it {expect(response_request.body).to include "[RevMan]"}
  end

  context 'when admin request extraction review page' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      get '/review/1/extract_information'
    end

    it "should show the information summary at the beginning" do
      expect(last_response).to be_ok
      expect(last_response.body).to include "Articles with information"
      expect(last_response.body).to include "1 / 1"
      expect(last_response.body).to include "Articles pending information upload"
    end
  end

  context 'when enter information on form' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      put '/review/1/extract_information/cd/1/user/1/update_field', :pk=>'stages', :value=>'NEW VALUE'
    end
    let(:row_on_ds) {$db["SELECT * FROM analysis_sr_1 WHERE user_id=? AND canonical_document_id=?", 1, 1].first}
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}

    it {puts last_response.body; expect(last_response).to be_ok}
    it {expect(row_on_ds[:stages]).to eq("NEW VALUE")}
    it {expect(response_request.body).to include "NEW VALUE"}


  end

  context 'when uploading a guideline file for extraction' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      FileExtractionInformation.dataset.delete
      uploaded_file=Rack::Test::UploadedFile.new(File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/README.md"), "text/plain", true)
      post '/review/1/extract_information/cd/1/file_extraction_information/add', :file_extraction_information=>uploaded_file
    end

    let(:file_extraction_information) {FileExtractionInformation.first}

    it {expect(last_response).to be_redirect}

    it "should create the guideline reference" do
      expect(file_extraction_information).to be_truthy
      expect(file_extraction_information[:systematic_review_id]).to eq(1)
      expect(file_extraction_information[:canonical_document_id]).to eq(1)
      expect(file_extraction_information[:user_id]).to eq(1)
      expect(IFile[file_extraction_information[:file_id]]).to be_truthy
      expect(FileSr[:systematic_review_id=>1, :file_id=>file_extraction_information[:file_id]]).to be_truthy
    end

    it "should show the guideline on the extraction form" do
      get '/review/1/extract_information/cd/1'
      expect(last_response).to be_ok
      expect(last_response.body).to include("Pautas de extracción")
      expect(last_response.body).to include("README.md")
    end

    it "should mark the file as guideline on files page" do
      get '/review/1/files'
      expect(last_response).to be_ok
      expect(last_response.body).to include("Pauta")
    end

    it "should delete the guideline reference" do
      post "/review/1/extract_information/cd/1/file_extraction_information/#{file_extraction_information[:id]}/delete"
      expect(last_response).to be_redirect
      expect(FileExtractionInformation[file_extraction_information[:id]]).to be_nil
    end
  end

  context 'when uploading multiple guideline files for extraction' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
      FileExtractionInformation.dataset.delete
      uploaded_file_1=Rack::Test::UploadedFile.new(File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/README.md"), "text/plain", true)
      uploaded_file_2=Rack::Test::UploadedFile.new(File.expand_path("#{File.dirname(__FILE__)}/../Gemfile"), "text/plain", true)
      post '/review/1/extract_information/cd/1/file_extraction_information/add', :file_extraction_information=>[uploaded_file_1, uploaded_file_2]
    end

    it "should create all guideline references" do
      expect(FileExtractionInformation.where(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1).count).to eq(2)
    end

    it "should show all guidelines on the extraction form" do
      get '/review/1/extract_information/cd/1'
      expect(last_response).to be_ok
      expect(last_response.body).to include("README.md")
      expect(last_response.body).to include("Gemfile")
    end
  end


  context 'when admin request form for a not included document (2)' do
    before(:each) do
      post '/login', :user=>'admin', :password=>'admin'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/2'; last_response}
    it {expect(response_request).to be_redirect}


  end

  context 'when request form response by not assigned user' do
    before(:each) do
      post '/login', :user=>'analyst', :password=>'analyst'
    end
    let(:response_request) {  get '/review/1/extract_information/cd/1'; last_response}
    it {expect(response_request).to_not be_ok}
    it {expect(response_request).to be_redirect}
  end



end
