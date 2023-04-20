require 'spec_helper'

describe 'Pager on evaluation of papers' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite # TODO: REMOVE DEPENDENCE ON COMPLETE SQLITE
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
      get '/review/1/screening_title_abstract?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+29<\/p>/)
    end

  end

  context 'when screening title abstract using query' do

    it "shows a document if title is retrieved" do
      get '/review/1/screening_title_abstract?query=title(SLURP)'
      expect(last_response.body).to include("A Tool to Help Large")
    end

  end

  context 'when screening references' do

    it "shows that are 26 documents to review " do
      get '/review/1/screening_references'
      expect(last_response.body).to include("26")
    end
    it "shows 9 documents with decision=yes " do
      get '/review/1/screening_references?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+9<\/p>/)
    end

  end

  context 'when reviewing full text' do

    it "shows that are 30 documents to review " do
      get '/review/1/review_full_text'
      expect(last_response.body).to include("30")
    end
    it "shows 27 documents with decision=yes " do
      get '/review/1/review_full_text?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+27<\/p>/)
    end
  end

  context 'when reviewing full text using tags' do

    it "shows 22 documents using tag_select" do
      tag_id=Tag[:text=>'tools'].id
      get "/review/1/review_full_text?tag_select[]=#{tag_id}"
      expect(last_response.body).to match(/<p.+id='count_search'.+22<\/p>/)
    end
  end


end