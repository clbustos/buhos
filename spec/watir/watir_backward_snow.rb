require 'watir'
require 'webdrivers'
require 'fileutils'


Dir.mktmpdir do |dir| 
  `git clone git@github.com:clbustos/buhos.git #{dir}/buhos`
  Dir.chdir "#{dir}/buhos"
  `rackup`
  base_fixtures=File.expand_path(File.dirname(__FILE__)+"/spec/fixtures/")
  browser=Watir::Browser.new
  browser.goto 'localhost:9292'
  browser.select_list(:id => "language").option(:value => "en").select
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.link(:id=>'populate_database').when_present.click
  browser.link(:id=>'end_installation').when_present.click



  browser.goto 'localhost:9292'
  browser.text_field(:name=>'user').set('admin')
  browser.text_field(:name=>'password').set('admin')
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click
  browser.link(:text =>"New systematic review").when_present.click
  browser.text_field(:name=>'name').set('Test Tertiary studies on SE and GSD')
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click

  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "1").select
  browser.textarea(:name=>'search_criteria').set('TITLE-ABS-')
  browser.text_field(:name=>'description').set('Search on Scopus')
  browser.file_field(:name=>'file').set("#{base_fixtures}/scopus_tertiary.bib")
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click

  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "2").select
  browser.textarea(:name=>'search_criteria').set('TITLE-ABS-')
  browser.text_field(:name=>'description').set('Search on Wos')
  browser.file_field(:name=>'file').set("#{base_fixtures}/wos_tertiary.bib")
  browser.element(:xpath=>"//input[@type='submit'][1]").when_present.click


  browser.link(:text =>"New search based on bibliographic files").when_present.click
  browser.select_list(:id => "bibliographic_database_id").option(:value => "6").select
  browser.textarea(:name=>'search_criteria').set('TITLE-ABS-')
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
  browser.link(:text =>"Include Document").when_present.click

  # Exclude three texts
  browser.button(:id =>"resolution-19-no").when_present.click
  browser.button(:id =>"resolution-5-no").when_present.click
  browser.button(:id =>"resolution-24-no").when_present.click

  browser.refresh
  browser.link(:text =>"Advance to next stage").when_present.click
  browser.screenshot.save ("~/without_crossref.png")
  browser.link(:text =>"My dashboard").when_present.click
  browser.link(:text =>/Title and abstract screening/).when_present.click
  browser.link(:id =>"dashboard-1-administrator-screening_title_abstract").when_present.click
  browser.link(:text =>"Generate references using Crossref").click
  browser.link(:text =>"My dashboard")..wait_until_present(60*5).click
  browser.screenshot.save ("~/with_crossref.png")
end
