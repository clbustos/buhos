require 'spec_helper'
require_relative "../lib/pdf_file_processor"

describe 'PdfFileProcessor' do
  def get_filepath(filename)
    File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
  end
  def get_file1
    get_filepath("2010_Kiritchenko_et_al_ExaCT_automatic_extraction_of_clinical_trial_characteristics_from_journal_publications.pdf")
  end

  before(:all) do
    app_helper=Class.new {extend Buhos::Helpers}
    @dir_files=app_helper.dir_files
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    SystematicReview.insert(:id=>1,:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    Search.insert(id:1,systematic_review_id:1, bibliographic_database_id:1,search_type:'uploaded_files')


    login_admin
  end
  it "should raise exception if Search is not uploaded_files type" do
    Search.insert(id:2,systematic_review_id:1, bibliographic_database_id:1, search_type:'other_type')
    pfp_local=PdfFileProcessor.new(Search[2], get_file1, @dir_files)
    expect {pfp_local.process}.to raise_error(FileProcessor::NoUploadedFilesType)
  end
  context "when process is executed" do
    before(:context) do
      @pfp=PdfFileProcessor.new(Search[1], get_file1, @dir_files)
      @pfp.process
      @uid=@pfp.uid
    end
    let(:sr) {SystematicReview[id:1]}

    let(:record) {Record[uid:@uid]}
    let(:ifile)  {IFile.first}
    let(:can_doc)  {CanonicalDocument.first}
    it "should add a correct file object" do
      expect(IFile.count).to eq(1)
      expect(ifile[:filetype]).to eq("application/pdf")
      expect(ifile[:filename]).to eq(File.basename(get_file1))
      expect(ifile[:sha256]).to eq(@uid.gsub("file:",""))
      #expect(ifile[])
    end
    it "should add a correct Record" do
      expect(record).to be_truthy
      expect(record[:uid]).to eq(@uid)
    end
    it "should add a correct RecordSearch" do
      recser=RecordsSearch[record_id:record.id, search_id:1]
      ifile=IFile.first
      expect(recser).to be_truthy
      expect(recser[:file_id]).to eq(ifile[:id])
    end
    it "should create a new CanonicalDocument" do
      expect(CanonicalDocument.count).to eq(1)
      expect(can_doc).to be_truthy
    end
    it "should add a correct FileCd" do
      filecd=FileCd[canonical_document_id:can_doc.id, file_id:ifile.id]
      expect(filecd).to be_truthy
      expect(filecd.not_consider).to be_falsey
    end
    it "should add a correct FileSr" do
      filesr=FileSr[systematic_review_id:sr.id, file_id:ifile.id]
      expect(filesr).to be_truthy
      #expect(filesr.not_consider).to be_falsey
    end

  end








end