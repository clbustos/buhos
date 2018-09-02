require 'spec_helper'

describe 'Stage administration using external data' do
  def pmid_ex
    28501917
  end
  def doi_ex
    "10.1007/s00204-017-1980-3"
  end
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    CanonicalDocument[1].update(:title=>"Using Framework Analysis in nursing research: a worked example.", :doi=>doi_ex, :pmid=>pmid_ex)
    Search[1].update(:valid=>true)
    login_admin
  end

  context "when canonical_documents/review/:rev_id/complete_pubmed_pmid is called" do
    before(:context) do
      CanonicalDocument[1].update(pmid:nil)
      get '/canonical_documents/review/1/complete_pubmed_pmid'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should pmid be correct" do
      expect(CanonicalDocument[1].pmid.to_s).to eq(pmid_ex.to_s)
    end
  end

  context "when /review/:rev_id/stage/:stage/generate_crossref_references is called" do
    before(:context) do
      CanonicalDocument[1].update(abstract:nil)
      get '/review/1/stage/review_full_text/generate_crossref_references'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end

  end
  context "when /review/:rev_id/stage/:stage/complete_empty_abstract_pubmed is called" do
    before(:context) do
      CanonicalDocument[1].update(abstract:nil)
      get '/review/1/stage/review_full_text/complete_empty_abstract_pubmed'
    end
    it "should response be ok" do
      expect(last_response).to be_redirect
    end
    it "should include correct abstract on canonical document" do
      expect(CanonicalDocument[1].abstract).to include("pioneered in the clinical field,")
    end

  end

  context "when search for crossref references" do
    before(:context) do
      get '/canonical_document/1/search_crossref_references'
    end
    it {expect(last_response).to be_redirect}
  end

  context "when search for crossref data" do
    before(:context) do
      get '/canonical_document/1/get_crossref_data'
    end
    it {expect(last_response).to be_redirect}
  end

  context "when search for pubmed data" do
    before(:context) do
      CanonicalDocument[1].update(:pmid=>pmid_ex)
      get '/canonical_document/1/get_pubmed_data'
    end
    it {expect(last_response).to be_redirect}
  end


  context "when update information of a canonical document using crossref" do
    before(:context) do
      #CrossrefDoi[doi:"10.1111/jocn.13259"].delete
      CanonicalDocument[1].update(title:nil, author: nil)
      get '/canonical_document/1/update_using_crossref_info'
      #$log.info(CanonicalDocument[64])
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
  end


end
