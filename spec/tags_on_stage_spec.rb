require 'spec_helper'

describe 'Tags on stage forms' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
    login_admin
  end

  context "when tag added on a document" do
    before(:context) do
      post '/tags/cd/40/rs/1/add_tag', value:'new_tag'
    end
    it {expect(last_response).to be_ok}
    it "should response body include new tag" do
      expect(last_response.body).to include "new_tag"
    end
    let(:tag_en_cd) {
      tag_id=Tag[text:'new_tag'][:id]
      TagInCd[user_id:1,tag_id:tag_id, canonical_document_id:40, systematic_review_id:1]
    }
    it "should object tag_en_cd created " do
      expect(tag_en_cd).to be_truthy
    end

    it "should decision attr should be 'yes'" do
      expect(tag_en_cd[:decision]).to eq('yes')
    end
  end
  context "when view of canonical documents for a review and a stage is retrieved" do
    before(:context) do
      tag_id=Tag[text:'new_tag'][:id]
      get "/tag/#{tag_id}/rs/1/stage/screening_title_abstract/cds"
    end
    it do
      #$log.info(last_response.body)
      expect(last_response).to be_ok
    end
  end

  context "when view of canonical documents for a review is retrieved" do
    before(:context) do
      tag_id=Tag[text:'new_tag'][:id]
      get "/tag/#{tag_id}/rs/1/cds"
    end
    it do

      expect(last_response).to be_ok
    end
  end

  context "when tag added for a relation between documents" do
    before(:context) do
      post '/tags/cd_start/2/cd_end/88/rs/1/add_tag', value:'new_relation_tag'
    end
    it {expect(last_response).to be_ok}
    it "should response body include new tag" do
      expect(last_response.body).to include "new_relation_tag"
    end
    let(:tag_en_cd) {
      tag_id=Tag[text:'new_relation_tag'][:id]

      TagBwCd[user_id:1,tag_id:tag_id, cd_start:2, cd_end:88, systematic_review_id:1]
    }
    it "should object tag_en_cd created " do
      expect(tag_en_cd).to be_truthy
    end

    it "should decision attr should be 'yes'" do
      expect(tag_en_cd[:decision]).to eq('yes')
    end
  end


  context "when previous tag is approved by another user" do
    before(:context) do
      login_admin
      post '/tags/cd/40/rs/1/add_tag', value:'new_tag_2'

      tag_id=Tag.get_tag('new_tag_2')[:id]
      post '/login', user:'analyst', password:'analyst'


      post '/tags/cd/40/rs/1/approve_tag', tag_id:tag_id
    end
    it {expect(last_response).to be_ok}
    it "should response body include new tag" do
      expect(last_response.body).to include "new_tag_2"
    end

    let(:tag_en_cd) {
      tag_id=Tag[text:'new_tag_2'][:id]

      TagInCd.where(tag_id:tag_id, canonical_document_id:40, systematic_review_id:1)
    }
    it "should object tag_en_cd created " do
      expect(tag_en_cd).to be_truthy
    end

    it "should be two 'yes' decisions" do
      expect(tag_en_cd.where(:decision=>'yes').count).to eq(2)
    end
  end

  context "when previous tag is rejected by another user" do
    before(:context) do
      login_admin
      post '/tags/cd/40/rs/1/add_tag', value:'new_tag_3'

      tag_id=Tag.get_tag('new_tag_3')[:id]
      post '/login', user:'analyst', password:'analyst'

      post '/tags/cd/40/rs/1/reject_tag', tag_id:tag_id
    end
    it {expect(last_response).to be_ok}
    it "should response body include new tag" do
      expect(last_response.body).to include "new_tag_3"
    end

    let(:tag_en_cd) {
      tag_id=Tag[text:'new_tag_3'][:id]

      TagInCd.where(tag_id:tag_id, canonical_document_id:40, systematic_review_id:1)
    }
    it "should object tag_en_cd created " do
      expect(tag_en_cd).to be_truthy
    end

    it "should be one 'yes' and one 'no ' decisions" do
      expect(tag_en_cd.where(:decision=>'yes').count).to eq(1) and expect(tag_en_cd.where(:decision=>'no').count).to eq(1)
    end
  end



  context "when json for typeahead are retrieved" do
    it{expect('/tags/basic_10.json').to be_available}
    it{expect('/tags/basic_ref_10.json').to be_available}
    it{expect('/tags/query_json/new_ta').to be_available}
    it{expect('/tags/refs/query_json/new_relat').to be_available}
    it{expect('/tags/systematic_review/1/query_json/new_ta').to be_available}
    it{expect('/tags/systematic_review/1/ref/query_json/new_relat').to be_available}
  end

  context "when analyzing tags from specific systematic review and user" do
    before(:context) do
      login_admin
      get '/review/1/tags/user/1'
    end
    it "should response be ok" do
      expect(last_response).to be_ok
    end
  end


  context "when renaming tag from specific systematic review and user" do
    before(:context) do
      login_admin
      old_tag=Tag.get_tag("Flying birds")
      TagInCd.insert(tag_id:old_tag[:id], user_id:1, systematic_review_id:1, decision:'yes', canonical_document_id:40)
      put '/tag/rename/review/1/user/1', pk:old_tag.id, value: "Excellents birds"
    end

    it "should create a link between new tag and document" do
      new_tag=Tag.get_tag("Excellents birds")
      expect(TagInCd.where(user_id:1, systematic_review_id:1, decision:'yes', canonical_document_id:40, tag_id:new_tag[:id]).count).to eq(1)
    end
    it "should delete reference for old tag" do
      expect(Tag.where(text:'Flying birds').count).to eq(0)
    end

    it "should delete the link between old tag and document" do
      old_tag=Tag.where(text:"Flying birds")
      expect(TagInCd.where(user_id:1, systematic_review_id:1, decision:'yes', canonical_document_id:40, tag_id:old_tag[:id]).count).to eq(0)
    end

    after(:context) do
      tags=Tag.where(text:['Flying birds', 'Excellents birds'])
      TagInCd.where(tag_id:tags.map(&:id)).delete
      tags.delete

    end
  end

end