require 'spec_helper'

describe 'Pager on evaluation of papers' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  before(:each) do
    post '/login' , :user=>'admin', :password=>'admin'
  end
  context 'when screening title abstract' do

    it "shows that are 85 documents to review " do
      get '/review/1/screening_title_abstract'
      expect(last_response.body).to include("85")
    end
    it "shows 29 documents with decision=yes " do
      get '/review/1/screening_title_abstract?query=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+29<\/p>/)
    end

  end

  context 'when screening references' do

    it "shows that are 26 documents to review " do
      get '/review/1/screening_references'
      expect(last_response.body).to include("26")
    end
    it "shows 9 documents with decision=yes " do
      get '/review/1/screening_references?query=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+9<\/p>/)
    end

  end

  context 'when reviewing full text' do

    it "shows that are 30 documents to review " do
      get '/review/1/review_full_text'
      expect(last_response.body).to include("30")
    end
    it "shows 27 documents with decision=yes " do
      get '/review/1/review_full_text?query=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+27<\/p>/)
    end

  end



end