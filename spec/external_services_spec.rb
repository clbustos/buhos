require 'spec_helper'

describe 'Stage administration using external data' do
  def pmid_ex
    28501917
  end
  def doi_ex
    "10.1007/s00204-017-1980-3"
  end

  def doi_ref
    "10.1177/14614456020040040101"
  end

  def pre_context
    sr_for_report
    CanonicalDocument[1].update(:title=>"Using Framework Analysis in nursing research: a worked example.", :doi=>doi_ex, :pmid=>pmid_ex)
    Search[1].update(:valid=>true)
    @reference_text="Antaki C. (2002) Personalised revision of ‘failed’ questions. Discourse Studies 4(4), 411–428."
    @ref_id=Reference.calculate_id(@reference_text)
    Reference.insert(:id=>@ref_id, :text=>@reference_text)
    RecordsReferences.insert(record_id:1, reference_id:@ref_id)

    unless ENV["NO_CROSSREF_MOCKUP"]
      $db[:crossref_dois].insert(:doi=>doi_ex,:json=>read_fixture("10.1007___s00204-017-1980-3.json"))
      $db[:crossref_dois].insert(:doi=>doi_ref,:json=>read_fixture("10.1177___14614456020040040101.json"))

      $db[:crossref_queries].insert(:id=>'32e989d317ea4172766cc80e484dceaebd67dd7a962a15891ad0bd1eef6428af',:json=>read_fixture('32e989d317ea4172766cc80e484dceaebd67dd7a962a15891ad0bd1eef6428af.json'))
      $db[:crossref_queries].insert(:id=>'b853d71e3273321a0423a6b4b4ebefb313bfdef4c3d133f219c1e8cb0ef35398',:json=>read_fixture('b853d71e3273321a0423a6b4b4ebefb313bfdef4c3d133f219c1e8cb0ef35398.json'))
    end
  end
  def after_context
    SystematicReview[1].delete
    $db[:records_references].delete
    $db[:records_searches].delete
    $db[:records].delete
    $db[:bib_references].delete
    $db[:canonical_documents].delete
    $db[:crossref_dois].delete
    $db[:crossref_queries].delete
    $db[:searches].delete
  end
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    login_admin
  end

  context "when /references/search_crossref_by_doi/:doi is used with a doi assigned to a ref" do
    before(:context) do
      pre_context
      Reference[@ref_id].update(doi:doi_ref)
      get "/references/search_crossref_by_doi/#{doi_ref.gsub('/','***')}"
    end
    it "should redirect" do
      p last_response.body
      expect(last_response).to be_redirect
    end
    it "should create a canonical document with correct doi" do
      expect(CanonicalDocument.where(doi:doi_ref).count).to eq(1)
    end


    after(:context) do
      after_context
    end
  end


  context "when add_doi on a valid reference" do
    before(:context) do
      pre_context
      Reference[@ref_id].add_doi(doi_ref)
    end
    let(:cd_assoc) {CanonicalDocument.where(:doi=>doi_ref).first}
    it "should create a canonical document with correct information" do
      expect(cd_assoc).to be_truthy
    end
    it "should link reference to canonical document with correct information" do
      expect(Reference[@ref_id].canonical_document_id).to eq(cd_assoc.id)
    end
    after(:context) do
      after_context
    end

  end

  context "when /record/:id/search_crossref is called with a record" do
    before(:context) do
      pre_context
      Record[1].update(title:'Using Framework Analysis')
      get "/record/1/search_crossref"
    end
    it "should show a page including the name of reference" do
      expect(last_response.body).to include "Using Framework Analysis"
    end
    after(:context) do
      after_context
    end
  end


  context "when /reference/:id/search_crossref is called with a ref without doi" do
    before(:context) do
      pre_context
      get "/reference/#{@ref_id}/search_crossref"
    end
    it "should show a page including the name of reference" do
      expect(last_response.body).to include @reference_text
    end
    after(:context) do
      after_context
    end
  end

  context "when /reference/:id/search_crossref is called with a ref with a doi" do
    before(:context) do
      pre_context
      Reference[@ref_id].update(doi:doi_ref)
      get "/reference/#{@ref_id}/search_crossref"
    end

    it "should redirect" do
      expect(last_response).to be_redirect
    end
    it "should create a canonical document with correct doi" do
      expect(CanonicalDocument.where(doi:"10.1177/14614456020040040101").count).to eq(1)
    end
    after(:context) do
      after_context
    end
  end


  context "when /search/:id/records/complete_doi is called" do
    before(:context) do
      pre_context
      $db[:records_references].delete
      $db[:bib_references].delete
      Record[1].update(:title=>"Using Framework Analysis in nursing research: a worked example", :year=>2013, :author=>"Ward, D. and Furber, C. and Tierney, S. and Swallow, V.", :canonical_document_id=>1, :doi=>doi_ex)
      CanonicalDocument.insert(:title=>'dummy', :year=>0, :doi=>"10.1289/ehp.1307893")



      get '/search/1/records/complete_doi'
    end
    let(:cd_on_ref) {CanonicalDocument.where(:doi=>"10.1289/ehp.1307893").first}
    it "should create a correct crossref_integrator on Canonical Document" do
      expect(Record[1].canonical_document.crossref_integrator).to be_truthy
    end
    it "should create references assigned to record" do
      expect(Record[1].references.count).to eq(Record[1].canonical_document.crossref_integrator.references.count)
    end
    it "at least one reference have a doi assigned" do
      #$log.info(Record[1].references.all)
      expect(Record[1].references.any? {|v| !v[:doi].nil?}).to be_truthy
    end
    it "asign canonical document to reference with proper doi" do
      expect(Reference.where(:doi=>"10.1289/ehp.1307893").first[:canonical_document_id]).to eq(cd_on_ref[:id])
    end

    after(:context) do
      after_context
      $db[:crossref_dois].delete
    end

  end


  context "when /canonical_document/:id/search_crossref_references used" do
    before(:context) do
      pre_context
      Reference[@ref_id].update(:doi=>"10.1177/14614456020040040101")
      get '/canonical_document/1/search_crossref_references'
    end
    let(:cd_assoc) {CanonicalDocument.where(:doi=>"10.1177/14614456020040040101").first}
    it "should create a canonical document with correct information" do
      expect(cd_assoc).to be_truthy
    end
    it "should link reference to canonical document with correct information" do
      expect(Reference[@ref_id].canonical_document_id).to eq(cd_assoc.id)
    end
    after(:context) do
      after_context
    end

  end

  context "when canonical_documents/review/:rev_id/complete_pubmed_pmid is called" do
    before(:context) do
      pre_context
      CanonicalDocument[1].update(pmid:nil)
      get '/canonical_documents/review/1/complete_pubmed_pmid'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should pmid be correct" do
      expect(CanonicalDocument[1].pmid.to_s).to eq(pmid_ex.to_s)
    end
    after(:context) do
      after_context
    end
  end


  context "when /review/:rev_id/stage/:stage/complete_empty_abstract_scopus is called" do
    before(:context) do
      pre_context
      Scopus_Abstract.insert(:id=>"2-s2.0-85019269575", :doi=>"10.1007/s00204-017-1980-3", :xml=>read_fixture("scopus_ex_1.xml"))
      CanonicalDocument[1].update(abstract:nil)
      get '/review/1/stage/review_full_text/complete_empty_abstract_scopus'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should include correct abstract on canonical document" do
      expect(CanonicalDocument[1].abstract).to include("pioneered in the clinical field,")
    end
    after(:context) do
      $db[:scopus_abstracts].delete
      after_context
    end

  end

  context "when /canonical_documents/review/:review_id/complete_abstract_scopus is called" do
    before(:context) do
      pre_context
      Scopus_Abstract.insert(:id=>"2-s2.0-85019269575", :doi=>"10.1007/s00204-017-1980-3", :xml=>read_fixture("scopus_ex_1.xml"))
      CanonicalDocument[1].update(abstract:nil)
      get '/canonical_documents/review/1/complete_abstract_scopus'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should include correct abstract on canonical document" do
      expect(CanonicalDocument[1].abstract).to include("pioneered in the clinical field,")
    end
    after(:context) do
      $db[:scopus_abstracts].delete
      after_context
    end

  end

  context "when /canonical_document/:id/search_abstract_scopus is called" do
    before(:context) do
      pre_context
      Scopus_Abstract.insert(:id=>"2-s2.0-85019269575", :doi=>"10.1007/s00204-017-1980-3", :xml=>read_fixture("scopus_ex_1.xml"))
      CanonicalDocument[1].update(abstract:nil)
      get '/canonical_document/1/search_abstract_scopus'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should include correct abstract on canonical document" do
      expect(CanonicalDocument[1].abstract).to include("pioneered in the clinical field,")
    end
    after(:context) do
      $db[:scopus_abstracts].delete
      after_context
    end

  end






  context "when /review/:rev_id/stage/:stage/complete_empty_abstract_pubmed is called" do
    before(:context) do
      pre_context
      CanonicalDocument[1].update(abstract:nil)
      get '/review/1/stage/review_full_text/complete_empty_abstract_pubmed'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should include correct abstract on canonical document" do
      expect(CanonicalDocument[1].abstract).to include("pioneered in the clinical field,")
    end
    after(:context) do
      after_context
    end

  end


  context "when search for crossref references" do
    before(:context) do
      pre_context
      get '/canonical_document/1/search_crossref_references'
    end
    it {expect(last_response).to be_redirect}
    after(:context) do
      after_context
    end
  end

  context "when search for crossref data" do
    before(:context) do
      pre_context
      get '/canonical_document/1/get_external_data/crossref'
    end
    it {expect(last_response).to be_redirect}
    after(:context) do
      after_context
    end
  end

  context "when search for pubmed data" do
    before(:context) do
      pre_context
      CanonicalDocument[1].update(:pmid=>pmid_ex)
      get '/canonical_document/1/get_external_data/pubmed'
    end
    it {expect(last_response).to be_redirect}
    after(:context) do
      after_context
    end
  end


  context "when update information of a canonical document using crossref" do
    before(:context) do
      pre_context
      CanonicalDocument[1].update(title:nil, author: nil)
      get '/canonical_document/1/update_using_crossref_info'
    end
    let(:cd) {CanonicalDocument[1]}
    let(:cr) {CanonicalDocument[1].crossref_integrator}
    it "expect last response to be redirect" do
      #$log.info(last_response.body)
      expect(last_response).to be_redirect
    end
    it "should update correct title and author" do
      #$log.info(cd)
      expect(cd.title).to eq cr.title
      expect(cd.author).to eq cr.author
    end
    after(:context) do
      after_context
    end
  end
  context "when /search/:id/references/generate_canonical_doi/:n called using crossref" do
    before(:context) do
      pre_context
      get '/search/1/references/generate_canonical_doi/20'
    end

    it "expect last response to be redirect" do
      expect(last_response).to be_redirect
    end
    it "should update correct title and author" do

    end
    after(:context) do
      after_context
    end



  end


end
