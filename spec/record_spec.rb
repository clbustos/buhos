require 'spec_helper'

describe 'Record' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  let(:referencia) {Registro[1]}
  context "#crossref_query result" do
    let(:crossref_query) {Registro[1].crossref_query}
    it {
      expect(crossref_query).to be_a(Array)
    }
    it "every element should have a doi" do
      expect(crossref_query.all? {|v| v.keys.include?('doi')}).to be true
    end
  end
  context "#referencias_id" do
    it "should retrieve 77 references" do
      expect(Registro[1].referencias_id.count).to eq(77)
    end
  end

  context "#add_doi_automatic result on a reference with doi and canonical with doi" do

    let(:result) {Registro[1].add_doi_automatic}
    it {
      expect(result).to be_a(::Result)
    }
    it "nothing to do" do
      expect(result.events[0][:message]).to eq(I18n::t(:nothing_to_do))
    end
  end

  context "#add_doi_automatic result on a reference with doi, but canonical without it" do
    before(:each) do
      @canonical_id=Registro[1].canonico_documento_id
      Canonico_Documento[@canonical_id].update(:doi=>nil)
      @result=Registro[1].add_doi_automatic
    end

    it {
      expect(@result).to be_a(::Result)
    }
    let(:cd) {Canonico_Documento[@canonical_id]}
    it "should add doi to canonical document" do
      expect(cd[:doi]).to eq(Registro[1].doi)
    end

    it "should send a message that doi is already added on record" do
      expect(@result.events[0][:message]).to eq(I18n::t("record.already_added_doi", doi:Registro[1].doi, record_id:1))
    end
    it "should send a message that doi is assigned to canonical document" do
      expect(@result.events[1][:message]).to eq(I18n::t("record.assigned_doi_to_cd", doi:Registro[1].doi, cd_title:cd[:title]))
    end

  end

  context "#references_automatic_crossref" do
    before(:context) do
      referencias=Referencia_Registro.where(registro_id:1).map(:referencia_id)

      referencias_in=referencias.map{|v| "'#{v}'"}.join(',')

      $db.run("DELETE FROM referencias_registros WHERE registro_id=1")
      $db.run("DELETE FROM referencias_registros WHERE referencia_id IN (#{referencias_in})")
      $db.run("DELETE FROM referencias WHERE id IN (#{referencias_in})")

      @result=Registro[1].references_automatic_crossref
    end
    it {
      expect(@result).to be_a(::Result)
    }
    it "should process 38 references" do
      expect(@result.events[0][:message]).to include("38")
    end
    it "record should have now 38 references" do
      expect(Referencia_Registro.where(registro_id:1).count).to eq(38)
    end
  end

end