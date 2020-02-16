require 'spec_helper'

# TODO: Check references on bibtex
describe 'BibliographicFileProcessor' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_sr
    create_search
    CrossrefDoi.insert(:doi=>"10.1186/s13643-016-0263-z", :json=>read_fixture("10.1186___s13643-016-0263-z.json")) unless ENV["NO_CROSSREF_MOCKUP"]
  end
  after(:all) do
    $db[:crossref_dois].delete
  end

  def manual_bibtex
    File.read(File.dirname(__FILE__)+"/../docs/guide_resources/manual.bib")
  end

  def minimal_bibtex
    dois=["10.1145/2372233.2372243", "10.1186/s13643-016-0263-z", "10.1186/1472-6947-10-56", "10.1186/s13643-017-0421-y", "10.1186/1471-2105-9-205", "10.1136/bmj.38636.593461.68"]
    dois.map{|v| "@article{a#{v.gsub(/[\/\.-]/,'')},\ntitle={{#{v}}},\ndoi = {#{v}}\n}" }.join("\n")
  end


  context "when invalid file is used" do
    before(:context) do
      Search[1].update(:file_body=>"NOTHING RELEVANT", :filename=>'nothing.txt', :filetype => 'text/plain')
    end
    before do
      @bpf=BibliographicFileProcessor.new(Search[1])
    end
    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end

    it "should #result contain a message" do
      expect(@bpf.result.count).to eq(1)
    end

    it "should #result contain a message with the search id" do


      mes1=I18n::t('bibliographic_file_processor.no_integrator_for_filetype')
      expect(@bpf.result.events[0][:message]).to match(/#{mes1}.+ID 1\s*$/)
    end
    it "should not create any record" do
      expect(Record.count).to eq(0)
    end
    it "should not create any canonical document" do
      expect(CanonicalDocument.count).to eq(0)
    end

    it "should #canonical_document_processed be false" do
      expect(@bpf.canonical_document_processed).to be false
    end
    after do
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end

  context "when usual BibTeX is used" do
    before(:context) do
      Search[1].update(:file_body=>manual_bibtex, :filename=>'manual.bib', :filetype => 'text/x-bibtex')
    end
    before do
      @bpf=BibliographicFileProcessor.new(Search[1])
    end
    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end

    it "should #result contain two messages" do
      expect(@bpf.result.count).to eq(2)
    end

    it "should #result contain two messages with the correct search and canonical id" do
      mes1=I18n::t('bibliographic_file_processor.Search_process_file_successfully')
      mes2=I18n::t('bibliographic_file_processor.Search_canonical_documents_successfully')
      expect(@bpf.result.events[0][:message]).to match(/#{mes1}.+ID 1\s*$/)
      expect(@bpf.result.events[1][:message]).to match(/#{mes2}.+ID 1\s+#{I18n::t(:Count_canonical_documents)}\s+:\s+6$/)
    end

    it "should create 6 records" do
      expect(Record.count).to eq(6)
    end
    it "should create 6 canonical documents" do
      expect(CanonicalDocument.count).to eq(6)
    end
    it "should #canonical_document_processed be true" do
      expect(@bpf.canonical_document_processed).to be true
    end

    after do
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end



  context "when a basic BibTeX is used" do
    before(:context) do
      Search[1].update(:file_body=>minimal_bibtex, :filename=>'manual.bib', :filetype => 'text/x-bibtex')
    end
    before do
      @bpf=BibliographicFileProcessor.new(Search[1])
    end
    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end
    it "should create 6 records" do
      expect(Record.count).to eq(6)
    end


    it "should #result contain two messages" do
      expect(@bpf.result.count).to eq(2)
    end

    it "should #result contain two messages with the correct search and canonical id" do
      mes1=I18n::t('bibliographic_file_processor.Search_process_file_successfully')
      mes2=I18n::t('bibliographic_file_processor.Search_canonical_documents_successfully')
      expect(@bpf.result.events[0][:message]).to match(/#{mes1}.+ID 1\s*$/)
      expect(@bpf.result.events[1][:message]).to match(/#{mes2}.+ID 1\s+#{I18n::t(:Count_canonical_documents)}\s+:\s+6$/)
    end

    it "should create 6 canonical documents" do
      expect(CanonicalDocument.count).to eq(6)
    end
    it "should not have info for authors" do
      w_author=CanonicalDocument.find_all {|v| !v[:author].nil?}
      expect(w_author.count).to eq(0)
    end
    after do
      $db[:records_references].delete

      $db[:bib_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end

  context "when a basic BibTeX is used and later updated" do
    before do
      Search[1].update(:file_body=>minimal_bibtex, :filename=>'manual.bib', :filetype => 'text/x-bibtex')
      @bpf=BibliographicFileProcessor.new(Search[1])
      Search[1].update(:file_body=>manual_bibtex, :filename=>'manual.bib', :filetype => 'text/x-bibtex')
      @bpf=BibliographicFileProcessor.new(Search[1])
    end
    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end




    it "should maintain 6 records" do
      expect(Record.count).to eq(6)
    end
    it "should maintain 6 canonical documents" do
      expect(CanonicalDocument.count).to eq(6)
    end
    it "should update authors " do
      w_author=CanonicalDocument.find_all {|v| !v[:author].nil?}
      expect(w_author.count).to eq(6)
    end

    after do
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end

  context "when erroneous Scopus BibTeX is used" do
    before do
      Search[1].update(:file_body=>read_fixture("scopus_wrong.bib"), :filename=>'manual.bib', :filetype => 'text/x-bibtex')
      @bpf=BibliographicFileProcessor.new(Search[1])

    end
    it "should #error be true" do
      expect(@bpf.error).to be_falsey
    end
    it "should maintain 11 records" do
      expect(Record.count).to eq(11)
    end

    it "should maintain 11 canonical documents" do
      expect(CanonicalDocument.count).to eq(11)
    end

    after do
      $db[:records_references].delete
      $db[:bib_references].delete

      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end

  end

  context "when erroneous BibTeX is used" do
    before do
      Search[1].update(:file_body=>minimal_bibtex.gsub(",",""), :filename=>'manual.bib', :filetype => 'text/x-bibtex')
      @bpf=BibliographicFileProcessor.new(Search[1])

    end
    it "should #error be true" do
      expect(@bpf.error).to be_truthy
    end
    it "should #result contain a message" do
      expect(@bpf.result.count).to eq(1)
    end

    it "should #result contain a message with the search id" do


      mes1=I18n::t('bibliographic_file_processor.error_parsing_file')
      expect(@bpf.result.events[0][:message]).to match(/#{mes1}.+ID 1.+BibTeX.+/)
    end
    it "should not create any record" do
      expect(Record.count).to eq(0)
    end
    it "should not create any canonical document" do
      expect(CanonicalDocument.count).to eq(0)
    end

    after do
      $db[:records_references].delete
      $db[:bib_references].delete

      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end



  context "when a real BibTeX with references is used" do
    before do
      Search.where(:id=>2).delete
      Search.insert(:id=>2, :systematic_review_id=>1, :bibliographic_database_id=>1, :file_body=>read_fixture("wos.bib"), :filename=>'wos.bib', :filetype => 'text/x-bibtex')

      @bpf=BibliographicFileProcessor.new(Search[2])
    end

    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end
    it "should maintain 1 records" do
      expect(Record.count).to eq(1)
    end
    it "should maintain 1 canonical documents" do
      expect(CanonicalDocument.count).to eq(1)
    end

    it "should create 353 references" do
      expect(Reference.count).to eq(353)
    end


    after do
      $db[:records_references].delete
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end


  context "when a real Scielo BibTeX is used" do
    def bibtex_text
      read_fixture("scielo.bib")
    end
    before(:context) do
      Search[1].update(:file_body=>bibtex_text, :filename=>'manual.bib', :filetype => 'text/x-bibtex')
    end
    before do
      @bpf=BibliographicFileProcessor.new(Search[1])
    end
    it "should error be false" do
      expect(@bpf.error).to be_falsey
    end


    it "should create 13 records" do
      expect(Record.count).to eq(13)
    end

    it "should create 13 canonical documents" do
      expect(CanonicalDocument.count).to eq(13)
    end
    it "should all canonical documents have correct titles" do
      bt=read_fixture("scielo.bib")
      titles=bt.each_line.inject([]) {|ac,v|
        if v=~/title\s*=\s*\{\{(.+)\}\}/
          ac.push($1)
        end
        ac
      }

      titles_recorded=Record.all.map {|v| v[:title]}
      expect(titles-titles_recorded).to eq([])
    end
    it "should #canonical_document_processed be true" do
      expect(@bpf.canonical_document_processed).to be true
    end
    after do
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end
  end

  context "when #get_integrator is called" do

    before do
      Search.where(:id=>2).delete
      Search.insert(:id=>2, :systematic_review_id=>1, :bibliographic_database_id=>1, :file_body=>"", :filename=>'strange.no_type', :filetype => 'unknown/x-unknown')

      @bpf=BibliographicFileProcessor.new(Search[2])
    end
    it "should retrieve false " do
      expect(@bpf.get_integrator).to be false
    end
    after do
      $db[:records_references].delete
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end

  end

end