require 'spec_helper'

describe 'Reference' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    login_admin
  end


  def reference_text_1
    "Antaki C. (2002) Personalised revision of ‘failed’ questions. Discourse Studies 4(4), 411–428."
  end
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
    CanonicalDocument.insert(id:2, :title=>"Not using Framework Analysis in medical research: a non worked example.", :doi=>"10.1007/non", :author=>'someone', :year=>2012)

    Search[1].update(:valid=>true)

    create_references(texts: [reference_text_1,"Not using framework", "Reference without CD"],
                      cd_id:[1, 2, nil],
                      record_id:1)
    Reference.get_by_text(reference_text_1).update(doi:doi_ex)

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

  let(:reference) do
    ref_id=Reference.calculate_id(reference_text_1)
    Reference[:id=>ref_id]
  end

  context 'when methods to retrieve references are used' do
    before(:context) do
      pre_context
    end
    it "#get_by_text should retrieve a reference object" do
      expect(Reference.get_by_text(reference[:text])).to eq(reference)
    end

    it "#get_by_text_and_doi should retrieve a correct reference object" do
      expect(Reference.get_by_text_and_doi(reference[:text], reference[:doi])).to eq(reference)
    end

    it "#get_by_text_and_doi(x,x,false) should retrieve nil if reference doesn't exists" do
      Reference.where(doi:'10.XXX').delete
      expect(Reference.get_by_text_and_doi('not exists','10.XXX')).to be_nil
    end

    it "#get_by_text_and_doi(x,x,true) should retrieve a new reference if doesn't exists" do
      ref=Reference.get_by_text_and_doi('not exists','10.XXX',true)
      expect(ref).to be_truthy
      expect(ref).to eq(Reference.get_by_text('not exists'))
    end
    after(:context) do
      after_context
    end

  end


  context "#search_similars is used, without considering references with canonical documents" do
    before(:context) do
      pre_context
    end
    after(:context) do
      after_context
    end
    let(:result) {reference.search_similars(100)} # We use 100 to speed the process
    it "should return an array" do
      expect(result).to be_a(Array)
      expect(result.length).to be >= 1

    end
    it "every element should have fields :id, :canonical_document_id, :text, :distancia" do

      expect(result.all? {|v|  v.keys.sort==[:canonical_document_id, :distancia, :id, :text] }).to be true
    end
    it "no element should have canonical_document_id assigned" do
      expect(result.all? {|v|  v[:canonical_document_id].nil? }).to be true
    end
  end

  context "#search_similars is used, considering references with canonical documents" do
    before(:context) do
      pre_context
    end
    after(:context) do
      after_context
    end
    let(:result) {reference.search_similars(100, false)}
    it "should return an array" do
      expect(result).to be_a(Array)
      expect(result.length).to be >= 1
    end
    it "every element should have fields :id, :canonical_document_id, :text, :distancia" do

      expect(result.all? {|v|  v.keys.sort==[:canonical_document_id, :distancia, :id, :text] }).to be true
    end
    it "at least one element should have canonical_document_id assigned" do
      expect(result.any? {|v|  !v[:canonical_document_id].nil? }).to be true
    end
  end


  context "#add_doi when no DOI exists" do
    before(:context) do
      pre_context
      Reference.get_by_text(reference_text_1).update(canonical_document_id:nil, doi:nil)
    end
    after(:context) do
      after_context
    end

    let(:result)  { Reference.get_by_text(reference_text_1).add_doi(doi_ex)  }
    let(:cd)      { CanonicalDocument[:doi=>doi_ex] }
    let(:ref)     { Reference.get_by_text(reference_text_1) }
    it "should return correct status" do
      expect(result.success?).to be true
    end
    it "should return correct doi" do
      expect(ref[:doi]).to eq(doi_ex)
    end

    it "should assign correct canonical document to reference" do
      expect(ref[:canonical_document_id]).to eq(cd[:id])
    end
  end


  context "#crossref_query when need to query crossref using text" do
    before(:context) do
      pre_context
      Reference.get_by_text(reference_text_1).update(canonical_document_id:nil, doi:nil)
    end
    after(:context) do
      after_context
    end
    let(:cq) { Reference.get_by_text(reference_text_1).crossref_query }
    it "should return an Hash" do
      expect(cq).to be_a(Hash)
    end
    it "should include doi 10.1177/14614456020040040101" do
      ref_int=BibliographicalImporter::JSONApiCrossref::Reader.parse_json(cq)
      expect(ref_int[0].doi).to eq(doi_ref)
    end
  end

end