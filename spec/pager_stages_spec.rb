require 'spec_helper'

describe 'Pager on evaluation of papers' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    create_stage_dataset
  end
  before(:each) do
    post '/login' , :user=>'admin', :password=>'admin'
  end

  context 'when screening title abstract' do

    it "shows that are 5 documents to review " do
      get '/review/1/screening_title_abstract'
      expect(last_response.body).to include("5")
    end
    it "shows 3 documents with decision=yes " do
      get '/review/1/screening_title_abstract?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+3<\/p>/)
    end

  end

  context 'when screening title abstract using query' do

    it "shows a document if title is retrieved" do
      get '/review/1/screening_title_abstract?query=title(SLURP)'
      expect(last_response.body).to include("A Tool to Help Large")
    end

  end

  context 'when screening references' do

    it "shows that are 3 documents to review " do
      get '/review/1/screening_references'
      expect(last_response.body).to include("3")
    end
    it "shows 1 document with decision=yes " do
      get '/review/1/screening_references?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+1<\/p>/)
    end

  end

  context 'when reviewing full text' do

    it "shows that are 4 documents to review " do
      get '/review/1/review_full_text'
      expect(last_response.body).to include("4")
    end
    it "shows 3 documents with decision=yes " do
      get '/review/1/review_full_text?decision=yes'
      expect(last_response.body).to match(/<p.+id='count_search'.+3<\/p>/)
    end
  end

  context 'when reviewing full text using tags' do

    it "shows 3 documents using tag_select" do
      tag_id=Tag[:text=>'tools'].id
      get "/review/1/review_full_text?tag_select[]=#{tag_id}"
      expect(last_response.body).to match(/<p.+id='count_search'.+3<\/p>/)
    end
  end

end
