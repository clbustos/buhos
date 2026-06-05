require 'spec_helper'

describe 'Extract information administration statistics' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    sr_for_report
    CanonicalDocument.insert(:id=>2, :title=>"Title 2", :year=>2021)
    create_record(:id=>[2], :cd_id=>[2], :search_id=>[1])
    Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>2,
                      :user_id=>1, :stage=>'review_full_text', :resolution=>'yes')
    AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1,
                        :user_id=>1, :stage=>'extract_information')
    AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>2,
                        :user_id=>2, :stage=>'extract_information')
    quality_criterion=QualityCriterion.get_criterion('quality criterion')
    SrQualityCriterion.insert(:systematic_review_id=>1, :quality_criterion_id=>quality_criterion[:id],
                              :scale_id=>1, :order=>1)
    CdQualityCriterion.insert(:systematic_review_id=>1, :canonical_document_id=>1,
                              :user_id=>1, :quality_criterion_id=>quality_criterion[:id],
                              :scale_id=>1, :value=>1)
    file_id=IFile.insert(:filename=>'guideline.txt', :filetype=>'text/plain', :sha256=>'guideline')
    FileExtractionInformation.insert(:systematic_review_id=>1, :canonical_document_id=>2,
                                     :user_id=>2, :file_id=>file_id)
    @quality_criterion_id=quality_criterion[:id]
    login_admin
  end

  context "when quality information is missing for an assigned extraction" do
    before(:context) do
      get '/review/1/administration/extract_information'
    end

    it "should response be ok" do expect(last_response).to be_ok end

    it "should show extraction information statistics" do
      expect(last_response.body).to include('Estadísticas de completitud')
      expect(last_response.body).to include('2 / 2')
      expect(last_response.body).to include('La etapa de extracción de información está incompleta.')
    end
  end

  context "when checking dashboard pending extraction information" do
    before(:each) do
      @file_extraction_information_rows=FileExtractionInformation.all.map(&:values)
      FileExtractionInformation.dataset.delete
      get '/review/1/dashboard'
    end

    after(:each) do
      @file_extraction_information_rows.each {|row| FileExtractionInformation.insert(row)}
    end

    it "should show pending articles without extraction information" do
      expect(last_response).to be_ok
      expect(last_response.body).to include('Number of articles pending information upload')
      expect(last_response.body).to include('1')
    end
  end

  context "when checking dashboard pending extraction information by role" do
    before(:each) do
      @file_extraction_information_rows=FileExtractionInformation.all.map(&:values)
      FileExtractionInformation.dataset.delete
      CanonicalDocument.insert(:id=>3, :title=>"Title 3", :year=>2022)
      create_record(:id=>[3], :cd_id=>[3], :search_id=>[1])
      Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>3,
                        :user_id=>1, :stage=>'review_full_text', :resolution=>'yes')
      AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>3,
                          :user_id=>1, :stage=>'extract_information')
      @analyst_review_edit_authorization=AuthorizationsRole[:authorization_id=>'review_edit', :role_id=>'analyst']
      AuthorizationsRole.insert(:authorization_id=>'review_edit', :role_id=>'analyst') unless @analyst_review_edit_authorization
    end

    after(:each) do
      FileExtractionInformation.dataset.delete
      @file_extraction_information_rows.each {|row| FileExtractionInformation.insert(row)}
      AllocationCd.where(:systematic_review_id=>1, :canonical_document_id=>3).delete
      Resolution.where(:systematic_review_id=>1, :canonical_document_id=>3).delete
      RecordsSearch.where(:record_id=>3).delete
      Record.where(:id=>3).delete
      CanonicalDocument.where(:id=>3).delete
      AuthorizationsRole.where(:authorization_id=>'review_edit', :role_id=>'analyst').delete unless @analyst_review_edit_authorization
    end

    it "should show only the user's pending assigned information to analysts" do
      post '/login', :user=>'analyst', :password=>'analyst'
      get '/review/1/dashboard'

      expect(last_response).to be_ok
      expect(last_response.body).to include('<strong>Number of articles pending information upload:</strong>&nbsp;1')
    end

    it "should show total pending information to administrators" do
      post '/login', :user=>'admin', :password=>'admin'
      get '/review/1/dashboard'

      expect(last_response).to be_ok
      expect(last_response.body).to include('<strong>Number of articles pending information upload:</strong>&nbsp;2')
    end
  end

  context "when all assigned extractions have information and quality" do
    before(:context) do
      CdQualityCriterion.insert(:systematic_review_id=>1, :canonical_document_id=>2,
                                :user_id=>2, :quality_criterion_id=>@quality_criterion_id,
                                :scale_id=>1, :value=>1)
      get '/review/1/administration/extract_information'
    end

    it "should show the extraction stage as complete" do
      expect(last_response.body).to include('La etapa de extracción de información está completa.')
    end
  end
end
