require 'spec_helper'

# TODO: Check references on bibtex
describe 'Bibliographic File Processor' do
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
    it "should create 6 records" do
      expect(Record.count).to eq(6)
    end
    it "should create 6 canonical documents" do
      expect(CanonicalDocument.count).to eq(6)
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
    it "should create 6 canonical documents" do
      expect(CanonicalDocument.count).to eq(6)
    end
    it "should not have info for authors" do
      w_author=CanonicalDocument.find_all {|v| !v[:author].nil?}
      expect(w_author.count).to eq(0)
    end
    after do
      $db[:bib_references].delete
      $db[:records_references].delete
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

  context "when erroneous BibTeX is used" do
    before do
      Search[1].update(:file_body=>minimal_bibtex.gsub(",",""), :filename=>'manual.bib', :filetype => 'text/x-bibtex')
      @bpf=BibliographicFileProcessor.new(Search[1])

    end
    it "should .error be true" do
      expect(@bpf.error).to be_truthy
    end
    it "should not create any record" do
      expect(Record.count).to eq(0)
    end
    it "should not create any canonical document" do
      expect(CanonicalDocument.count).to eq(0)
    end

    after do
      $db[:bib_references].delete
      $db[:records_references].delete
      $db[:records_searches].delete
      $db[:records].delete
      $db[:canonical_documents].delete
    end

  end



end