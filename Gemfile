source 'https://rubygems.org'
#gem 'rack-mini-profiler'
#gem 'stackprof'
#gem 'flamegraph'
gem 'libcache'
gem 'rufus-scheduler'
gem 'tzinfo-data'
gem 'mail'
gem 'rake', ">=13.0.0"
gem 'rack'
gem "rubyzip",  ">= 1.3.0"
gem 'zip-zip'
gem "sinatra",  '>=2.0.1'
gem "sequel"
gem "mysql2"
gem "json"
gem "haml"
gem "rspec"
gem "rack-test"
gem 'bibtex-ruby'
gem "unicode"
#gem 'levenshtein-ffi', :force_ruby_platform=>true , :require => 'levenshtein'
gem 'levenshtein-ffi', :require => 'levenshtein', :git => 'https://github.com/remix/levenshtein-ffi.git'
gem 'elsevier_api', :git => 'https://github.com/clbustos/elsevier_api.git'
gem 'levenshtein'
gem 'narray'
gem 'serrano'
gem 'dotenv'
gem 'treetop'
gem 'nokogiri', :force_ruby_platform=> true
gem 'moneta'
gem 'ruby-stemmer', :git => 'https://github.com/clbustos/ruby-stemmer.git'
#gem 'categorize' , :platforms => :ruby
gem 'pdf-reader'
gem 'grim', :git=>"https://github.com/GeneralProducts/grim"
gem "i18n"
gem "sqlite3", :force_ruby_platform=>:true
gem 'mimemagic'
gem "certified", :platforms => :mingw
gem 'simple_xlsx_reader'
gem 'caxlsx'
gem 'tf-idf-similarity'
gem 'ref_parsers', :git=>'https://github.com/kariem2k/ref_parsers.git'

#gem 'rubyXL'
gem 'ai4r'

#gem 'nbayes'
#gem 'classifier-reborn'

group :production do
  gem "puma", :platforms => :mingw
  gem "thin", :force_ruby_platform=>true

end
group :development do
  gem 'pkgr'
  gem 'rubocop'
  gem 'yard', :require => false
  gem 'yard-sinatra', :require => false
  gem 'pry'
  gem 'mutant'
  gem 'mutant-rspec'
  gem "sassc"
end

group :test do
  gem 'simplecov', :require => false
  gem 'test-prof', :require => false
end

