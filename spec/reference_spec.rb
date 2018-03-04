require 'spec_helper'

describe 'Reference' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  let(:reference) {Reference.exclude(:doi=>nil).first}
  context 'when methods to retrieve references are used' do
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

  end
  context "#buscar_similares is used, without considering references with canonical documents" do
    let(:result) {Reference.exclude(:doi=>nil).first.search_similars(100)} # We use 100 to speed the process
    it "should return an array" do
      expect(result).to be_a(Array)
    end
    it "every element should have fields :id, :canonical_document_id, :text, :distancia" do
      expect(result.all? {|v|  v.keys.sort==[:canonical_document_id, :distancia, :id, :text] }).to be true
    end
    it "no element should have canonical_document_id assigned" do
      expect(result.all? {|v|  v[:canonical_document_id].nil? }).to be true
    end
  end

  context "#buscar_similares is used, considering references with canonical documents" do
    let(:result) {Reference.exclude(:doi=>nil).first.search_similars(100, false)}
    it "should return an array" do
      expect(result).to be_a(Array)
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
      ref=Reference.exclude(:doi=>nil, :canonical_document_id=>nil).first
      @doi=ref[:doi]
      ref.update(:doi=>nil,  :canonical_document_id=>nil)
      @ref_id=ref[:id]
    end
    let(:result) {Reference[@ref_id].add_doi(@doi)}
    let(:cd) {CanonicalDocument[:doi=>@doi]}
    let(:ref) {Reference[@ref_id]}
    it "should return correct status" do
      expect(result.success?).to be true
    end
    it "should return correct doi" do
      expect(ref[:doi]).to eq(@doi)
    end

    it "should assign correct canonical document to reference" do
      expect(ref[:canonical_document_id]).to eq(cd[:id])
    end
  end

  context "#crossref_query when need to query crossref using text" do
    before(:context) do
      res=$db['SELECT b.* FROM bib_references b INNER JOIN crossref_queries c where b.id=c.id LIMIT 1'].first
      @ref=Reference[res[:id]]
    end
    let(:cq) {@ref.crossref_query}
    it "should return an Array" do
      expect(cq).to be_a(Array)
    end
    it "should include doi http://dx.doi.org/10.1111/j.1708-8208.2003.tb00188.x" do
      expect(cq[0]["doi"]).to eq("http://dx.doi.org/10.1111/j.1708-8208.2003.tb00188.x")
    end
  end

end