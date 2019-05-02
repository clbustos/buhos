require 'simplecov'
unless ENV['NO_COV']
  SimpleCov.start do
    add_filter '/spec/'
    add_filter 'lib/scopus/connection.rb' # Is necessary an API scopus to test it
  end
end
require 'sequel'
require 'rspec'
require 'i18n'
require 'fileutils'
require 'rack/test'
require 'tempfile'
require 'logger'
require_relative "../lib/buhos/create_schema"
require_relative "../lib/buhos/dbadapter"
require_relative 'rspec_matchers'

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL']='sqlite::memory:'


locales_root=File.join(File.dirname(__FILE__),'..', 'config','locales', '*.yml')

::I18n.load_path+=Dir[locales_root]
::I18n.locale=:en

$base=File.expand_path("..",File.dirname(__FILE__))


FileUtils::mkdir_p "#{$base}/log/"

logger_sql = Logger.new("#{$base}/log/spec_sql_test.log")

db=Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false)
Buhos::SchemaCreation.create_db_from_scratch(db)

$db_adapter=Buhos::DBAdapter.new
$db_adapter.logger=logger_sql
$db_adapter.use_db(db)

Sequel::Model.db=$db_adapter

require_relative "../app"

Buhos.connect_to_db($db_adapter)

#puts "#{$db.object_id} - #{$db_adapter.object_id}"

#exit





#SimpleCov.formatter = SimpleCov::Formatter::Codecov
# Load available locales
app_path=File.expand_path(File.dirname(__FILE__)+"/..")
::I18n.load_path+=Dir[File.join(app_path, 'config','locales', '*.yml')]
::I18n.config.available_locales = [:es,:en]

# Load rack test
#

#
# RSpec.configure do |config|
#   # ...
#   config.define_derived_metadata(file_path: %r{/spec/}) do |metadata|
#     # do not overwrite type if it's already set
#     next if metadata.key?(:type)
#
#     match = metadata[:location].match(%r{/spec/([^/]+)/})
#     match = metadata[:location].match(%r{/spec/([^_]+)}) if match.nil?
#
#     metadata[:type] = match[1].to_sym
#   end
# end

module RSpecMixin
  include Rack::Test::Methods

  shared_examples 'html standard report' do
    it "should response be ok" do expect(last_response).to be_ok end
    it "should include name of review" do
      expect(last_response.body).to include("Test Systematic Review")
    end
  end

  shared_examples 'excel standard report' do
    it "should response be ok" do expect(last_response).to be_ok end
    it "should content type be correct mimetype" do expect(last_response.header['Content-Type']).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') end
    it "should content dispostion be attachment and include .xlsx on name" do
      expect(last_response.header['Content-Disposition']).to include("attachment") and
          expect(last_response.header['Content-Disposition']).to include(".xlsx")
    end
  end


  def app() Sinatra::Application end
	def is_windows?
		(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def can_im_create_images_from_pdf?
    require 'grim'
    result=true
    begin
      tf=Tempfile.new

      pdf   = Grim.reap(fixture_path('empty_pdf.pdf'))
      pdf[0].save(tf.path,{
      :density=>100})
    rescue Grim::UnprocessablePage
      result=false
    ensure
      tf.close
      tf.unlink
    end
    result
  end
  def sr_by_name_id(name)
    rs=SystematicReview[:name=>name]
    rs ? rs[:id] : nil
  end

  # Create 1 or more systematic reviews, with standard titles
  # @return an array with systematic reviews ids
  def create_sr(n:1,  group_id:1, sr_administrator:1)
    1.upto(n).map do |i|
      SystematicReview.insert(:id=>i,:name=>"Test Systematic Review #{i}", :group_id=>group_id, :sr_administrator=>sr_administrator)
    end
  end

  def create_search(n:1,  id:nil, systematic_review_id:1, bb_id:1, user_id:1)
    ids_to_create =  id.nil? ? (1..n).to_a : id.to_a

    (0...ids_to_create.length).map do |i|
      #$log.info((ids_to_create[i]))
      Search.insert(:id=>(ids_to_create[i]),
                    :systematic_review_id       => systematic_review_id.respond_to?(:index) ? systematic_review_id.to_a[i] : systematic_review_id,
                    :bibliographic_database_id  => bb_id,
                    :user_id                    => user_id
                    )
    end
  end

  def create_record(n:1, id:nil, uid:nil, cd_id:nil, search_id:nil, bb_id:1)
    ids_to_create =  id.nil? ? (1..n).to_a : id.to_a

    (0...ids_to_create.length).map do |i|

      r_id=ids_to_create[i]
      r_uid=uid.nil? ? "test:#{r_id}" : r_uid[i]
      r_cd =cd_id.nil? ? nil : (cd_id.respond_to?('[]') ? cd_id[i] : cd_id)
      r_bb =bb_id.respond_to?(:index) ? bb_id[i] : bb_id

      r_id_r=Record.insert(id:r_id, uid:r_uid, canonical_document_id:r_cd, bibliographic_database_id:r_bb )
      unless search_id.nil?
        search_ids= search_id[i].respond_to?(:index) ? search_id[i] : [search_id[i]]
        #$log.info(search_ids)
        search_ids.each {|s_id| RecordsSearch.insert(:search_id=>s_id, :record_id=>r_id_r)   }
      end
      r_id_r
    end
  end

  def create_references(texts:, cd_id:nil, record_id:nil)

    cd_ids=cd_id.nil? ? nil : (cd_id.is_a?(Array) ? cd_id : [cd_id] * texts.length)
    records_id=record_id.nil? ? nil : (record_id.is_a?(Array) ? record_id: [record_id] * texts.length)
    (0...texts.length).map do |i|
      reference=Reference.get_by_text_and_doi(texts[i],nil, true)
      reference.update(canonical_document_id:cd_ids[i]) if cd_ids and !cd_ids[i].nil?
      if records_id
        RecordsReferences.insert(reference_id: reference.id, record_id: records_id[i])
      end
    end
  end

  def bb_by_name_id(name)
    bb=BibliographicDatabase[name:name]
    bb ? bb[:id] :nil
  end

  def configure_empty_sqlite

    db=Buhos::SchemaCreation.create_db_from_scratch(Sequel.connect('sqlite::memory:', :encoding => 'utf8',:reconnect=>false,:keep_reference=>false))
    $db_adapter.use_db(db)
    $db_adapter.update_model_association

    $log.info("DB is:#{$db}")
  end
  def login_admin
    post '/login', :user=>"admin", :password=>"admin"
  end
  def login_analyst
    post '/login', :user=>"analyst", :password=>"analyst"
  end

  def configure_complete_sqlite
	if(is_windows?)
		temppath="#{$base}/spec/usr/db_temp.sqlite"
		FileUtils.cp "#{$base}/db/db_complete.sqlite", temppath
		
		db=Sequel.connect("sqlite:/#{temppath}", :encoding => 'utf8',:reconnect=>false, :keep_reference=>false)
		temp=db
	else
		temp=Tempfile.new
		FileUtils.cp "#{$base}/db/db_complete.sqlite", temp.path
		# check next line. If we can 
		db=Sequel.connect("sqlite:#{temp.path}", :encoding => 'utf8',:reconnect=>false, :keep_reference=>false)
    end
	
    $db_adapter.use_db(db)
    $db_adapter.update_model_association



    #puts "Adaptador: #{$db_adapter.object_id} - #{User.db.object_id}"
    #puts "Db: #{$db_adapter.current.object_id} - #{$db.object_id} - #{db.object_id}"
    temp
  end

  def close_sqlite
    $log.info("Closing #{$db}")
    #$db.disconnect
    #$db_adapter.use_db(nil)
    #$db=nil

  end

  def permitted_redirect(url)
    get url
    expect(last_response).to_not be_ok
    expect(last_response.status).to_not eq(403)

  end

  def check_executable_on_path(exe)
    require 'mkmf'
    find_executable exe
  end

  # Create a systematic report with a form with 3 fields, 1 canonical document, 1 search, 1 record
  # and 2 positive resolutions for document 1
  def sr_for_report
    create_sr
    sr1=SystematicReview[1]
    sr1.stage='report'
    SrField.insert(:id=>1, :systematic_review_id=>1, :order=>1, :name=>"field_1", :description=>"Field 1", :type=>"textarea")
    SrField.insert(:id=>2, :systematic_review_id=>1, :order=>2, :name=>"field_2", :description=>"Field 2", :type=>"select", :options=>"a=a;b=b")
    SrField.insert(:id=>3, :systematic_review_id=>1, :order=>3, :name=>"field_3", :description=>"Field 3", :type=>"multiple", :options=>"a=a;b=b")
    SrField.update_table(sr1)
    CanonicalDocument.insert(:id=>1, :title=>"Title 1", :year=>0)
    create_search
    create_record(:cd_id=>1, :search_id=>1)
    $db[:analysis_sr_1].insert(:user_id=>1, :canonical_document_id=>1, :field_1=>"[campo1] [campo2]", :field_2=>"a",:field_3=>"a,b")
    Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1, :stage=>'screening_title_abstract', :resolution=>'yes')
    Resolution.insert(:systematic_review_id=>1, :canonical_document_id=>1, :user_id=>1, :stage=>'review_full_text', :resolution=>'yes')
    sr1
  end

  def doi_reference_1
    "10.1007/s10664-018-9626-5"
  end
  def sr_references
    sr_for_report
    Record[1].update(:author=>"Al-Zubidy, A and Carver JC", :title=>"Identification and prioritization of SLR search tool requirements: an SLR and a survey", :journal=>"Empir Softw Eng.", :year=>"2018", :pages=>"1–31", :doi=>"10.1007/s10664-018-9626-5")

    ref_1="Allman-Farinelli M, Byron A, Collins C, Gifford J, Williams P (2014) Challenges and lessons from systematic literature reviews for the australian dietary guidelines. Aust J Prim Health 20(3):236–240"
    ref_2="Babar MA, Zhang H (2009) Systematic literature reviews in software engineering: preliminary results from interviews with researchers. In: 3rd international symposium on empirical software engineering and measurement. IEEE Computer Society, pp 346–355"
    ref_3="Badampudi D, Wohlin C, Petersen K (2015) Experiences from using snowballing and database searches in systematic literature studies. In: 19th international conference on evaluation and assessment in software engineering. ACM, p 17"
    create_references(texts:[ref_1,ref_2 , ref_3], record_id:1)
  end

  def delete_references
    $db[:records_references].delete
    $db[:bib_references].delete
  end

  def read_fixture(filename)
    File.read(fixture_path(filename))
  end
  def fixture_path(filename)
    File.expand_path( File.join([File.dirname(__FILE__),"fixtures",filename   ]))
  end

end


module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end
  def is_windows?
		(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	end
end


#RSpec.configure { |c| c.include RSpecMixin }

