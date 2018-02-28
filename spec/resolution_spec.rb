require 'spec_helper'

describe 'Resolution on document' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
    Resolucion.where(:revision_sistematica_id=>1, :canonico_documento_id=>41, :etapa=>'screening_title_abstract').delete
  end
  context 'when resolution yes is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolucion:'yes', user_id:1
    end
    it {expect(last_response).to be_ok}
    it "should response body contain resolution partial " do
      expect(last_response.body).to include 'botones_resolucion_screening_title_abstract_41'
    end
    it "should resolution status be updated" do
      expect(Resolucion[:revision_sistematica_id=>1, :canonico_documento_id=>41, :etapa=>'screening_title_abstract'][:resolucion]).to eq('yes')
    end
  end

  context 'when resolution no is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolucion:'no', user_id:1
    end
    it {expect(last_response).to be_ok}
    it "should response body contain resolution partial " do
      expect(last_response.body).to include 'botones_resolucion_screening_title_abstract_41'
    end
    it "should resolution status be updated" do
      expect(Resolucion[:revision_sistematica_id=>1, :canonico_documento_id=>41, :etapa=>'screening_title_abstract'][:resolucion]).to eq('no')
    end
  end

  context 'when an incorrect resolution is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolucion:'OTHER', user_id:1
    end
    it {expect(last_response).to_not be_ok}
    it {expect(last_response.status).to eq(500)}
  end

end
