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
                    :user_id                    => user_id)
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
end


module RSpecMixinInstaller
  include Rack::Test::Methods
  def app() Buhos::Installer end

end


#RSpec.configure { |c| c.include RSpecMixin }

