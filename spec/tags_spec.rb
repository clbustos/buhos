require 'spec_helper'

describe 'Tags:' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    SystematicReview.insert(:name=>'Test Review', :group_id=>1, :sr_administrator=>1)
    login_admin

  end
  def create_class_tag(name,rev_id)
    post '/tags/classes/new', {review_id:rev_id, stage:nil, type:'document',name:name}
  end


  def t_class_ds(name)
    T_Class.where(:name=>name).first
  end
  def tag_ds(name)
    Tag[:text=>name]
  end
  def create_tag_inside_class_tag(tag_class_name,tag_name)
    t_class=t_class_ds(tag_class_name)
    post "/tags/class/#{t_class[:id]}/add_tag", value:tag_name
  end
  def delete_tag_inside_class_tag(tag_class_name,tag_id)
    t_class=t_class_ds(tag_class_name)
    post "/tags/class/#{t_class[:id]}/remove_tag", value:tag_id
  end

  def review_id
    SystematicReview.where(:name=>'Test Review').first[:id]
  end

  context 'when create a new tag class with a form' do
    before(:context) do
      create_class_tag('new1',review_id);
    end
    let!(:t_class) {t_class_ds('new1')}
    it "should response will be a redirect "  do  expect(last_response).to be_redirect end
    it "should be inserted into database"     do expect(t_class).to be_truthy end
  end

  context "when edit an attribute of a tag using PUT" do
    before(:context) do
      create_class_tag('new2',review_id)
      ntg=t_class_ds('new2')
      put '/tags/classes/edit_field/name', {pk:ntg[:id], :value=>'new3'}
    end
    let!(:ntg) {t_class_ds('new3')}

    it "should response will be ok " do expect(last_response).to be_ok end
    it "should have new name" do expect(ntg[:name]).to be_truthy end
  end
  context 'when create a new tag for a class tag' do

    before(:context) do
      create_class_tag('new3',review_id)
      create_tag_inside_class_tag('new3','tag1')
    end
    let(:t_class) {t_class_ds('new3')}
    let(:tag) {tag_ds('tag1')}
    it  "should response will be ok"      do expect(last_response).to be_ok end
    it "should Tag object exist"          do expect(tag).to be_truthy end
    it "shoult tag name appears on response" do expect(last_response.body).to include("tag1") end
    it "should TagInClass object exist" do  expect(TagInClass[tc_id: t_class[:id], tag_id: tag[:id]]).to be_truthy  end

  end


  context 'when delete a new tag for a class tag' do

    before(:context) do
      create_class_tag('new4',review_id)
      create_tag_inside_class_tag('new4','tag5')
      tag=Tag.get_tag('tag5')
      delete_tag_inside_class_tag('new4',tag[:id])

    end
    let(:t_class) {t_class_ds('new4')}
    let(:tag) {tag_ds('tag5')}
    it  "should response will be ok"      do expect(last_response).to be_ok end
    it "should not tag name appears on response" do expect(last_response.body).to_not include("tag5") end

    it "should TagInClass object not exist" do  expect(TagInClass[tc_id: t_class[:id], tag_id: tag[:id]]).to be_nil end

  end

  context "when delete a tag using /tag/delete_rs" do
    before(:context) do
      tag=Tag.get_tag('TAG1')
      CanonicalDocument.insert(:id=>1, :year=>0, :title=>'CD1')
      TagInCd.insert(systematic_review_id:1,tag_id:tag.id, user_id:1, canonical_document_id:1, decision:1  )
      post '/tag/delete_rs', :rs_id=>1, :tag_id=>tag.id
    end
    it "should not have any tag with name TAG1" do
      expect(Tag.where(:text=>'TAG1').count).to eq(0)
    end
    it "should not have any TagInCd with canonical document 1" do
      expect(TagInCd.where(:canonical_document_id=>1).count).to eq(0)
    end
    after(:context) do
      $db[:tag_in_cds].delete
      $db[:tag_in_classes].delete

      $db[:tags].delete

    end

  end

end