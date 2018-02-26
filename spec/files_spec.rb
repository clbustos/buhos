require 'spec_helper'

describe 'Files' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    Revision_Sistematica.insert(:nombre=>'Test Review', :grupo_id=>1, :administrador_revision=>1)
    login_admin
  end
  def rs_id(name)
    rs=Revision_Sistematica[:nombre=>name]
    rs ? rs[:id] : nil
  end
  context 'when upload a file using /review/files/add' do

    before(:context) do

      filename="2010_Kiritchenko et al._ExaCT automatic extraction of clinical trial characteristics from journal publications.pdf"
      path=File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
      uploaded_file=Rack::Test::UploadedFile.new(path, "application/pdf")
      post '/review/files/add', revision_sistematica_id:rs_id('Test Review'), archivos:[uploaded_file]
    end
    let(:file) {Archivo[1]}
    let(:app_helpers) {Class.new {extend Buhos::Helpers}}
    it "should response will be redirect" do expect(last_response).to be_redirect end
    it "should create an file object" do expect(file).to be_truthy end
    it "should create an file object with correct mime type" do expect(file[:archivo_tipo]).to eq("application/pdf") end
    it "should create a file on correct directory" do
      path="#{app_helpers.dir_archivos}/#{file[:archivo_ruta]}"
      expect(File.exist? path).to be true
    end
  end
end