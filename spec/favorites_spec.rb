require 'spec_helper'

describe 'Favorite documents' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    AllocationCd.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1,
                        :stage=>"screening_title_abstract")
    login_admin
  end

  let(:favorite) { FavoriteDocument.where(user_id: 1, canonical_document_id: 1).first }

  context 'when a favorite is created' do
    before(:context) do
      post '/favorite/user/1/canonical_document/1/add'
    end

    it { expect(last_response).to be_ok }
    it { expect(favorite).to_not be_nil }
    it { expect(favorite[:activo]).to eq(true) }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/remove' }
  end

  context 'when favorite commentary is modified' do
    before(:context) do
      put '/favorite/user/1/canonical_document/1/commentary_favorite', pk:1, value:'Favorite commentary'
    end

    it { expect(last_response).to be_ok }
    it { expect(favorite[:commentary]).to eq('Favorite commentary') }
  end

  context 'when the favorite is removed' do
    before(:context) do
      post '/favorite/user/1/canonical_document/1/remove'
    end

    it { expect(last_response).to be_ok }
    it { expect(FavoriteDocument.where(user_id: 1, canonical_document_id: 1).count).to eq(1) }
    it { expect(favorite[:activo]).to eq(false) }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/add' }
  end

  context 'when a deactivated favorite is added again' do
    before(:context) do
      post '/favorite/user/1/canonical_document/1/add'
    end

    it { expect(last_response).to be_ok }
    it { expect(FavoriteDocument.where(user_id: 1, canonical_document_id: 1).count).to eq(1) }
    it { expect(favorite[:activo]).to eq(true) }
    it { expect(favorite[:commentary]).to eq('Favorite commentary') }
  end

  context 'when screening title and abstract page shows an active favorite' do
    before(:context) do
      get '/review/1/screening_title_abstract'
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include 'favorite-cd-1-user-1' }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/remove' }
    it { expect(last_response.body).to include 'Favorite commentary' }
  end

  context 'when screening title and abstract page shows a deactivated favorite' do
    before(:context) do
      post '/favorite/user/1/canonical_document/1/remove'
      get '/review/1/screening_title_abstract'
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include 'favorite-cd-1-user-1' }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/add' }
    it { expect(last_response.body).to_not include '/favorite/user/1/canonical_document/1/remove' }
  end

  context 'when favorites are updated from user favorites page' do
    before(:context) do
      @group_id=FavoriteGroup.insert(user_id: 1, name: 'Important papers')
      post '/favorites/user/1/update', favorites: {
        '1' => {
          'activo' => '1',
          'group_id' => @group_id.to_s,
          'commentary' => 'Updated from favorites page'
        }
      }
    end

    it { expect(last_response).to be_redirect }
    it { expect(favorite[:activo]).to eq(true) }
    it { expect(favorite[:group_id]).to eq(@group_id) }
    it { expect(favorite[:commentary]).to eq('Updated from favorites page') }
  end

  context 'when a favorite is deactivated from user favorites page' do
    before(:context) do
      post '/favorites/user/1/update', favorites: {
        '1' => {
          'group_id' => '',
          'commentary' => 'Inactive from favorites page'
        }
      }
      get '/user/1/favorites'
    end

    it { expect(last_response).to be_ok }
    it { expect(favorite[:activo]).to eq(false) }
    it { expect(favorite[:group_id]).to be_nil }
    it { expect(last_response.body).to include 'Title 1' }
    it { expect(last_response.body).to include 'Inactive from favorites page' }
  end
end
