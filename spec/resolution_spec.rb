require 'spec_helper'

describe 'Resolution on document' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite # TODO: REMOVE DEPENDENCE ON COMPLETE SQLITE
    login_admin
    Resolution.where(:systematic_review_id=>1, :canonical_document_id=>41, :stage=>'screening_title_abstract').delete
  end
  context 'when resolution yes is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolution:'yes', user_id:1
    end
    it {expect(last_response).to be_ok}
    it "should response body contain resolution partial " do
      expect(last_response.body).to include 'botones_resolution_screening_title_abstract_41'
    end
    it "should resolution status be updated" do
      expect(Resolution[:systematic_review_id=>1, :canonical_document_id=>41, :stage=>'screening_title_abstract'][:resolution]).to eq('yes')
    end
  end

  context 'when resolution no is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolution:'no', user_id:1
    end
    it {expect(last_response).to be_ok}
    it "should response body contain resolution partial " do
      expect(last_response.body).to include 'botones_resolution_screening_title_abstract_41'
    end
    it "should resolution status be updated" do
      expect(Resolution[:systematic_review_id=>1, :canonical_document_id=>41, :stage=>'screening_title_abstract'][:resolution]).to eq('no')
    end
  end

  context 'when an incorrect resolution is adopted for specific document' do
    before(:context) do
      post '/resolution/review/1/canonical_document/41/stage/screening_title_abstract/resolution', resolution:'OTHER', user_id:1
    end
    it {expect(last_response).to_not be_ok}
    it {expect(last_response.status).to eq(500)}
  end

end
