require 'spec_helper'

describe 'Decision on documents' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end
  context 'when decision retrieved on screening title and abstract stage' do
    before(:context) do
      get '/decision/review/1/user/1/canonical_document/41/stage/screening_title_abstract'
    end
    it {expect(last_response).to be_ok}
    it {expect(last_response.body).to include '/decision/review/1/user/1/canonical_document/41/stage/screening_title_abstract/decision'}
  end

  context 'when decision retrieved on screening title and abstract stage with wrong argument' do
    before(:context) do
      get '/decision/review/1/user/1000/canonical_document/41/stage/screening_title_abstract'
    end
    it {expect(last_response).to_not be_ok}

  end


  context 'when decision button is pressed on screening title and abstract stage' do
    before(:context) do
      post '/decision/review/1/user/1/canonical_document/41/stage/screening_title_abstract/decision', decision:'undecided'
    end
    it {expect(last_response).to be_ok}
    it {expect(Decision[revision_sistematica_id:1, usuario_id:1, canonico_documento_id:41, etapa:"screening_title_abstract"][:decision]).to eq('undecided')}
    it {expect(last_response.body).to include '/decision/review/1/user/1/canonical_document/41/stage/screening_title_abstract/decision'}
  end

  context 'when commentary is added to decision' do
    before(:context) do
      put '/decision/review/1/user/1/canonical_document/41/stage/screening_title_abstract/commentary', pk:41, value:'COMMENTARY'
    end
    it {expect(last_response).to be_ok}
    it {expect(Decision[revision_sistematica_id:1, usuario_id:1, canonico_documento_id:41, etapa:"screening_title_abstract"][:comentario]).to eq('COMMENTARY')}

  end

end