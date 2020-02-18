source 'https://rubygems.org'
gem 'rake'
gem "rubyzip",  ">= 1.3.0"
gem 'zip-zip'
gem "sinatra",  '>=2.0.1'
gem "sequel"
gem "mysql2"
gem "haml"
gem "rspec"
gem "rack-test"
gem 'bibtex-ruby'
gem "unicode"
gem 'levenshtein-ffi', :platforms=>:ruby, :require => 'levenshtein'
#gem 'levenshtein-ffi', :require => 'levenshtein', :git => 'https://github.com/tosie/levenshtein-ffi.git'

gem 'levenshtein'
gem 'narray'
gem 'serrano'
gem 'dotenv'
gem 'treetop'
gem 'nokogiri', :platforms=> :ruby
gem 'moneta'
gem 'ruby-stemmer', :git => 'https://github.com/clbustos/ruby-stemmer.git'
gem 'categorize' , :platforms => :ruby
gem 'pdf-reader'
gem 'grim'
gem "i18n"
gem "sqlite3"
gem 'mimemagic'
gem "certified", :platforms => :mingw

gem 'axlsx' , ">=2.0.0"
gem 'tf-idf-similarity'

#gem 'rubyXL'
gem 'ai4r'
#gem 'scopus'
#gem 'nbayes'
#gem 'classifier-reborn'

group :production do
  gem "puma", :platforms => :mingw
  gem "thin", :platforms => :ruby

end
group :development do
  gem 'pkgr'
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

