require 'spec_helper'

describe 'Tags' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_sqlite
    Revision_Sistematica.insert(:nombre=>'Test Review', :grupo_id=>1, :administrador_revision=>1)

    login_admin

  end
  def create_class_tag(name,rev_id)
    post '/tags/classes/new', {revision_id:rev_id, etapa:nil, tipo:'documento',nombre:name}
  end


  def t_class_ds(name)
    T_Clase.where(:nombre=>name).first
  end
  def tag_ds(name)
    Tag[:texto=>name]
  end
  def create_tag_inside_class_tag(tag_class_name,tag_name)
    t_class=t_class_ds(tag_class_name)
    post "/tags/class/#{t_class[:id]}/add_tag", value:tag_name
  end

  def revision_id
    Revision_Sistematica.where(:nombre=>'Test Review').first[:id]
  end

  context 'when create a new tag class with a form' do
    before(:context) do
      create_class_tag('new1',revision_id);
    end
    let!(:t_class) {t_class_ds('new1')}
    it "should response will be a redirect "  do  expect(last_response).to be_redirect end
    it "should be inserted into database"     do expect(t_class).to be_truthy end
  end

  context "when edit an attribute of a tag using PUT" do
    before(:context) do
      create_class_tag('new2',revision_id)
      ntg=t_class_ds('new2')
      put '/tags/classes/edit_field/nombre', {pk:ntg[:id], :value=>'new3'}
    end
    let!(:ntg) {t_class_ds('new3')}

    it "should response will be ok " do expect(last_response).to be_ok end
    it "should have new name" do expect(ntg[:nombre]).to be_truthy end
  end
  context 'when create a new tag for a class tag' do

    before(:context) do
      create_class_tag('new3',revision_id)
      create_tag_inside_class_tag('new3','tag1')
    end
    let(:t_class) {t_class_ds('new3')}
    let(:tag) {tag_ds('tag1')}
    it  "should response will be ok"      do expect(last_response).to be_ok end
    it "should Tag object exist"          do expect(tag).to be_truthy end
    it "should Tag_En_Clase object exist" do  expect(Tag_En_Clase[tc_id: t_class[:id], tag_id: tag[:id]]).to be_truthy  end

  end


end