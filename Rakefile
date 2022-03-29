# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


require 'dotenv'
require 'logger'
require 'fileutils'

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'yard'
require 'yard-sinatra'



Dotenv.load("./.env")

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'model/**/*.rb', 'controllers/**/*.rb', '-', 'docs/rspec.html', 'LICENSE']   # optional
  t.options = ['--plugin yard-sinatra', '-odocs/api', '--embed-mixin'] # optional
  t.stats_options = ['--list-undoc']         # optional
end


# USE NO_CROSSREF_MOCKUP=1 to test crossref services

RSpec::Core::RakeTask.new(:spec) do |t|

  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format documentation'
# t.rspec_opts << ' more options'
  #t.rcov = true
end



RSpec::Core::RakeTask.new(:spec_html) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format html '
 t.rspec_opts << '--out docs/rspec.html '
#t.rcov = true
end



task :default => :spec

namespace :reflection do
  desc "Show authorizations"
  task :auth do |t|
    require_relative 'lib/buhos/reflection'
    app=Object.new
    def app.dir_base
      File.expand_path(File.dirname(__FILE__))
    end
    auth=Buhos::Reflection.get_authorizations(app)
    puts "Authorizations"
    puts "=============="
    puts auth.permits.join("\n")

  end
end


desc "Build .deb package"
task :build_deb do |t|
  require 'tmpdir'
  current_dir=File.expand_path(File.dirname(__FILE__))
  puts current_dir
  Dir.mktmpdir("buhos_pkgr") {|dir|
    sh %{git clone ./ "#{dir}"}
    sh %{rvmsudo pkgr package --name buhos "#{dir}"}
  }

  Dir.mkdir 'packages' unless Dir.exist? "packages"
  Dir.glob("*.deb") do |f|
    FileUtils.move f, "packages"
  end

end

desc "Update css using sass"
task :update_css => "public/stylesheets/main.css"
file "public/stylesheets/main.css" => ["public/stylesheets/sass/main.scss"] do |t|
  require 'sassc'
  css=SassC::Engine.new(File.read("public/stylesheets/sass/main.scss")).render
  File.open("public/stylesheets/main.css","w") {|fp| fp.write(css) }
end


namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    require 'i18n'

    locales_root=File.join(File.dirname(__FILE__),'config','locales', '*.yml')
    ::I18n.load_path+=Dir[locales_root]
    #::I18n.locale=:en

    require_relative 'lib/buhos/create_schema'
    base_dir=File.dirname(__FILE__)
    Sequel.extension :migration
    db = Sequel.connect(ENV["DATABASE_URL"])
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "#{base_dir}/db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "#{base_dir}/db/migrations")
      Buhos::SchemaCreation.create_bootstrap_data(db)
      Buhos::SchemaCreation.delete_views(db)

    end
  end



  desc "Update sqlite blank file"
  task :blank_sqlite => "db/blank.sqlite"

  file "db/blank.sqlite" => ["lib/buhos/create_schema.rb"] do
    require_relative 'lib/buhos/create_schema'
    require 'i18n'

    locales_root=File.join(File.dirname(__FILE__),'config','locales', '*.yml')
    ::I18n.load_path+=Dir[locales_root]

    log = Logger.new(STDOUT)
    FileUtils.rm("db/blank.sqlite") if File.exist? "db/blank.sqlite"
    Buhos::SchemaCreation.create_db_from_scratch("sqlite://db/blank.sqlite", "en",log)
  end
end
