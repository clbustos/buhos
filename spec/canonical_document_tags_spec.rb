require 'spec_helper'

describe 'Tags on canonical documents' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    sr_for_report
    Search[1].update(:valid=>true)
    CanonicalDocument[1].update(:title=>'This is the title')

    login_admin
  end

  def tag_1
    Tag.get_tag('tag1')
  end
  context "when tags action is called on /review/X/canonical_documents" do
    before(:context) do
      post '/canonical_document/actions', :action=>'tags',:sr_id=>1, :canonical_document=>{1=>'1'}, :url_back=>'', :user_id=>1
    end
    it "should redirect to the correct url" do
      expect(last_response).to be_redirect
    end

  end


  context "when /review/:sr_id/canonical_documents/tags/actions for add_for_all" do
    before(:context) do
      post "/review/1/canonical_documents/tags/actions", :action=>'add_for_all', :tags_all=>[tag_1.id], :cd_id=>"1", :url_back=>'', :user_id=>1
    end
    it "should redirect to the correct url" do
      expect(last_response).to be_redirect
    end
    it "should add a link between document and tag" do
      expect(TagInCd.where(:canonical_document_id=>1, :tag_id=>tag_1.id, :user_id=>1, :decision=>'yes').count).to eq(1)
    end
    after(:context) do
      $db[:tag_in_cds].delete
      $db[:tags].delete
    end
  end

  context "when /review/:sr_id/canonical_documents/tags/actions for remove_for_all" do
    before(:context) do
      post "/review/1/canonical_documents/tags/actions", :action=>'add_for_all', :tags_all=>[tag_1.id], :cd_id=>"1", :url_back=>'', :user_id=>1
      post "/review/1/canonical_documents/tags/actions", :action=>'remove_for_all', :tags_all=>[tag_1.id], :cd_id=>"1", :url_back=>'', :user_id=>1
    end
    it "should redirect to the correct url" do
      expect(last_response).to be_redirect
    end
    it "should add a link between document and tag" do
      expect(TagInCd.where(:canonical_document_id=>1, :tag_id=>tag_1.id, :user_id=>1, :decision=>'no').count).to eq(1)
    end
    after(:context) do
      $db[:tag_in_cds].delete
      $db[:tags].delete
    end
  end

  context "when /review/:sr_id/canonical_documents/tags/actions for remove_for_all" do
    before(:context) do
      post "/review/1/canonical_documents/tags/actions", :action=>'add_new', :new_tags=>'TAG 2', :cd_id=>"1", :url_back=>'', :user_id=>1
    end

    it "should redirect to the correct url" do
      expect(last_response).to be_redirect
    end
    it "should add a link between document and tag" do
      expect(TagInCd.where(:canonical_document_id=>1, :tag_id=>Tag.get_tag('TAG 2').id, :user_id=>1, :decision=>'yes').count).to eq(1)
    end
    after(:context) do
      $db[:tag_in_cds].delete
      $db[:tags].delete
    end
  end


end