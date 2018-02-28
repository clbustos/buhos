require 'spec_helper'

describe 'Reference' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  let(:referencia) {Referencia.exclude(:doi=>nil).first}
  context 'when methods to retrieve references are used' do
    it "#get_by_text should retrieve a reference object" do
      expect(Referencia.get_by_text(referencia[:texto])).to eq(referencia)
    end
    it "#get_by_text_and_doi should retrieve a correct reference object" do
      expect(Referencia.get_by_text_and_doi(referencia[:texto], referencia[:doi])).to eq(referencia)
    end
    it "#get_by_text_and_doi(x,x,false) should retrieve nil if reference doesn't exists" do
      Referencia.where(doi:'10.XXX').delete
      expect(Referencia.get_by_text_and_doi('not exists','10.XXX')).to be_nil
    end
    it "#get_by_text_and_doi(x,x,true) should retrieve a new reference if doesn't exists" do
      ref=Referencia.get_by_text_and_doi('not exists','10.XXX',true)
      expect(ref).to be_truthy
      expect(ref).to eq(Referencia.get_by_text('not exists'))
    end

  end
  context "#buscar_similares is used" do
    let(:result) {Referencia.exclude(:doi=>nil).first.buscar_similares}
    it "should return an array" do
      expect(result).to be_a(Array)
    end
    it "every element should have fields :id, :canonico_documento_id, :texto, :distancia" do
      expect(result.all? {|v|  v.keys.sort==[:canonico_documento_id, :distancia, :id, :texto] }).to be true
    end
  end

  context "#add_doi when no DOI exists" do
    before(:context) do
      ref=Referencia.exclude(:doi=>nil, :canonico_documento_id=>nil).first
      @doi=ref[:doi]
      ref.update(:doi=>nil,  :canonico_documento_id=>nil)
      @ref_id=ref[:id]
    end
    let(:result) {Referencia[@ref_id].add_doi(@doi)}
    let(:cd) {Canonico_Documento[:doi=>@doi]}
    let(:ref) {Referencia[@ref_id]}
    it "should return correct status" do
      expect(result.success?).to be true
    end
    it "should return correct doi" do
      expect(ref[:doi]).to eq(@doi)
    end

    it "should assign correct canonical document to reference" do
      expect(ref[:canonico_documento_id]).to eq(cd[:id])
    end
  end




end