require 'spec_helper'

describe 'Pager on evaluation of papers' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_database
    create_stage_dataset
    IFile.insert(:id=>1,
                 :filename=>'full_text.pdf',
                 :filetype=>'application/pdf',
                 :file_path=>'f/full_text.pdf',
                 :sha256=>'full-text-fixture')
    FileSr.insert(:file_id=>1, :systematic_review_id=>1)
    FileCd.insert(:file_id=>1, :canonical_document_id=>1)
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
    it "shows a file viewer link for assigned full-text files" do
      get '/review/1/review_full_text'
      expect(last_response.body).to include("data-target='#modalArchivos'")
      expect(last_response.body).to include("data-pk='1'")
      expect(last_response.body).to include('/file/1/download')
    end
    it "shows compact decision buttons" do
      get '/review/1/review_full_text'
      expect(last_response.body).to include("id='decision-1-yes'")
      expect(last_response.body).to include("id='decision-1-no'")
      expect(last_response.body).to include("data-compact='1'")
      expect(last_response.body).to include('/decision/review/1/user/1/canonical_document/1/stage/review_full_text/decision')
    end
    it "shows a commentary editor for the full text decision" do
      get '/review/1/review_full_text'
      expect(last_response.body).to include('/decision/review/1/user/1/canonical_document/1/stage/review_full_text/commentary')
      expect(last_response.body).to include('commentary-cd')
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
