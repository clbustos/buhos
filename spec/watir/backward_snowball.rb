# This example shows how to automate Buhos using watir for browser testing
# and a very fast backward-snowalling, based on a real application
require 'watir'
require 'webdrivers'
require 'fileutils'
dir=File.expand_path("~/.tmp")
base_fixtures=File.expand_path(File.dirname(__FILE__)+"/fixtures/")
base_png=File.expand_path(File.dirname(__FILE__)+"/")
Watir.default_timeout=60*10
puts `whoami`
  FileUtils.rm_rf(dir) if File.exists? dir 
  Dir.mkdir(dir) 
  
  port=rand(100)+9000
  
  `git clone ../../ #{dir}/buhos`
  Dir.mkdir("#{dir}/buhos/log") 
  File.chmod(0777, "#{dir}/buhos")
  File.chmod(0777, "#{dir}/buhos/log")
  Dir.chdir "#{dir}/buhos"
  
  system("rackup  -p #{port} -P #{dir}/pid &")
  sleep(2)
  browser=Watir::Browser.new
 
  browser.goto "localhost:#{port}"
  browser.select_list(:id => "language").option(:value => "en").select
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.radio(:id=>'configuration-advanced').set
  browser.text_field(:id=>'form-ncbi_api_key').set('dc7ad02f11bc2c47fc4e5d0706047e0ea308')
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.link(:id=>'populate_database').when_present.click
  browser.link(:id=>'end_installation').when_present.click


  pid=File.read("#{dir}/pid")
  `kill -s 9 #{pid}`
  
  system("rackup  -p #{port} -P #{dir}/pid &")
  sleep(5)


  browser.goto "localhost:#{port}"
  browser.screenshot.save ("#{base_png}/empty_system.png")
  browser.text_field(:name=>'user').set('admin')
  browser.text_field(:name=>'password').set('admin')
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.link(:text =>"New systematic review").when_present.click
  browser.text_field(:name=>'name').set('Tertiary studies about Systematic reviews on Software engineering/Global software engineering between 2017-2018')
  browser.text_field(:name=>'description').set('Test Tertiary studies on Software engineering and Global software engineering')

  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click

  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "1").select
  browser.textarea(:name=>'search_criteria').set('TITLE-ABS-KEY ( ( "Software engineering" OR "Global software engineering" ) AND "systematic literature review" AND "tertiary" ) AND PUBYEAR > 2008')
  browser.text_field(:name=>'description').set('Search on Scopus')
  browser.file_field(:name=>'file').set("#{base_fixtures}/scopus_tertiary.bib")
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click

  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "2").select
  browser.textarea(:name=>'search_criteria').set('TS=( ( "Software engineering" OR "Global software engineering" ) AND "systematic literature review" AND "tertiary" ) AND PY=(2009 OR 2010 OR 2011 OR 2012 OR 2013 OR 2014 OR 2015 OR 2016 OR 2017 OR 2018) ')
  browser.text_field(:name=>'description').set('Search on Wos')
  browser.file_field(:name=>'file').set("#{base_fixtures}/wos_tertiary.bib")
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click


  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "6").select
  browser.textarea(:name=>'search_criteria').set('((("Software engineering" OR "Global software engineering" ) AND "systematic literature review" AND "tertiary" ))')
  browser.text_field(:name=>'description').set('Search on IEEE')
  browser.file_field(:name=>'file').set("#{base_fixtures}/ieee_tertiary.bib")
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click

  # Fix the bad element

  browser.link(:text =>"Check 1 as yet unvalid record").when_present.click
  browser.link(:text =>/16th International Conference on Evaluation and Assessment in Software Engineering/).when_present.click
  browser.link(:id =>"canonical_document-author-19").when_present.click
  browser.text_field(:class=>"input-sm").set("NO AUTHOR")


  browser.button(:class=>"editable-submit").when_present.click


  #browser.link(:id =>"canonical_document-author-19").when_present.click

  browser.link(:text =>"My dashboard").when_present.click
  browser.link(:id =>"dashboard-1-administrator-search").when_present.click
  browser.link(:text =>"Advance to next stage").when_present.click
  browser.link(:text =>"Exclude Document").when_present.click
  
  sel=[1,5,20,21]
  
  sel.each do |cd_id|
    browser.button(:id=>"resolution-#{cd_id}-yes").click
  end
  

  browser.refresh
  browser.link(:text =>"Advance to next stage").when_present.click
  browser.screenshot.save ("#{base_png}/without_crossref.png")
  browser.link(:text =>"My dashboard").when_present.click
  browser.link(:text =>/Title and abstract screening/).when_present.click
  browser.link(:id =>"dashboard-1-administrator-screening_title_abstract").when_present.click
  browser.link(:text =>"Generate references using Crossref").click
  browser.link(:text =>"Back").click
  browser.link(:text =>"My dashboard").wait_until_present(60*5).click
  browser.screenshot.save ("#{base_png}/with_crossref.png")
  sleep(2)
  `kill -s 9 #{pid}`

