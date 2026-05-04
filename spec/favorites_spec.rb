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
    it { expect(last_response.body).to include '/canonical_document/1' }
    it { expect(last_response.body).to include 'Inactive from favorites page' }
  end

  context 'when active favorites are listed' do
    before(:context) do
      CanonicalDocument[1].update(abstract: 'Favorite abstract')
      FavoriteDocument.where(user_id: 1, canonical_document_id: 1).delete
      FavoriteDocument.create(user_id: 1, canonical_document_id: 1, activo: true)
      get '/user/1/favorites'
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include 'Title 1' }
    it { expect(last_response.body).to include '/canonical_document/1' }
    it { expect(last_response.body).to include "data-target='#cd-abstract-1'" }
  end

  context 'when public favorites are listed' do
    before(:context) do
      CanonicalDocument.where(id: 2).delete
      CanonicalDocument.insert(id: 2, title: 'Private favorite title', year: 0)
      @public_group_id=FavoriteGroup.insert(user_id: 1, name: 'Public collection', is_public: true)
      @private_group_id=FavoriteGroup.insert(user_id: 1, name: 'Private collection', is_public: false)
      FavoriteDocument.where(user_id: 1, canonical_document_id: [1, 2]).delete
      FavoriteDocument.create(user_id: 1, canonical_document_id: 1, activo: true, group_id: @public_group_id, commentary: 'Public favorite commentary')
      FavoriteDocument.create(user_id: 1, canonical_document_id: 2, activo: true, group_id: @private_group_id)
      get '/favorites'
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include 'Public favorites' }
    it { expect(last_response.body).to include 'Public collection' }
    it { expect(last_response.body).to include 'Title 1' }
    it { expect(last_response.body).to include 'Public favorite commentary' }
    it { expect(last_response.body).to_not include 'Private collection' }
    it { expect(last_response.body).to_not include 'Private favorite title' }
  end

  context 'when favorites page is shown with inactive favorites' do
    before(:context) do
      FavoriteDocument.where(user_id: 1, canonical_document_id: 1).delete
      FavoriteDocument.create(user_id: 1, canonical_document_id: 1, activo: false, commentary: 'Removed paper')
      get '/user/1/favorites'
    end

    it { expect(last_response).to be_ok }
    it { expect(last_response.body).to include 'favorites-trash-toggle' }
    it { expect(last_response.body).to include 'window.location.reload();' }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/restore' }
    it { expect(last_response.body).to include '/favorite/user/1/canonical_document/1/destroy' }
    it { expect(last_response.body).to include 'Removed paper' }
  end

  context 'when an inactive favorite is restored from the trash' do
    before(:context) do
      post '/favorite/user/1/canonical_document/1/restore'
    end

    it { expect(last_response).to be_ok }
    it { expect(FavoriteDocument[user_id: 1, canonical_document_id: 1][:activo]).to eq(true) }
  end

  context 'when an inactive favorite is permanently deleted from the trash' do
    before(:context) do
      FavoriteDocument.where(user_id: 1, canonical_document_id: 1).delete
      FavoriteDocument.create(user_id: 1, canonical_document_id: 1, activo: false)
      post '/favorite/user/1/canonical_document/1/destroy'
    end

    it { expect(last_response).to be_ok }
    it { expect(FavoriteDocument.where(user_id: 1, canonical_document_id: 1).count).to eq(0) }
  end

  context 'when a favorite category is created' do
    before(:context) do
      FavoriteGroup.where(user_id: 1, name: 'Favorites spec category').delete
      post '/favorite_groups/new', {name: 'Favorites spec category', is_public: 'true'}, 'HTTP_REFERER' => '/user/1/favorites'
      @group=FavoriteGroup[user_id: 1, name: 'Favorites spec category']
    end

    it { expect(last_response).to be_redirect }
    it { expect(@group).to_not be_nil }
    it { expect(@group[:is_public]).to eq(true) }
  end

  context 'when a favorite category is edited' do
    before(:context) do
      @group_id=FavoriteGroup.insert(user_id: 1, name: 'Category to edit', description: 'Before')
      put "/favorite_groups/#{@group_id}/edit_field/name", value: 'Edited category'
      put "/favorite_groups/#{@group_id}/edit_field/description", value: 'After'
      put "/favorite_groups/#{@group_id}/edit_field/is_public", value: '1'
    end

    it { expect(last_response).to be_ok }
    it { expect(FavoriteGroup[@group_id][:name]).to eq('Edited category') }
    it { expect(FavoriteGroup[@group_id][:description]).to eq('After') }
    it { expect(FavoriteGroup[@group_id][:is_public]).to eq(true) }
  end

  context 'when a favorite category belongs to another user' do
    before(:context) do
      @group_id=FavoriteGroup.insert(user_id: 2, name: 'Other user category')
      put "/favorite_groups/#{@group_id}/edit_field/name", value: 'Illegal edit'
    end

    it { expect(last_response.status).to eq(403) }
    it { expect(FavoriteGroup[@group_id][:name]).to eq('Other user category') }
  end

  context 'when a favorite category is deleted' do
    before(:context) do
      @group_id=FavoriteGroup.insert(user_id: 1, name: 'Category to delete')
      get "/favorite_group/#{@group_id}/delete", {}, 'HTTP_REFERER' => '/user/1/favorites'
    end

    it { expect(last_response).to be_redirect }
    it { expect(FavoriteGroup[@group_id]).to be_nil }
  end
end
