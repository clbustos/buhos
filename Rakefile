require 'dotenv'
require 'logger'
require 'fileutils'

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'


Dotenv.load("./.env")

task :doc do |t|
  sh %{yardoc -e lib_doc/yard_extra.rb *.rb controllers/**/*.rb lib/**/*.rb model/**/*.rb}
end




RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format documentation'

# t.rspec_opts << ' more options'
  #t.rcov = true
end
task :default => :spec


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

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    base_dir=File.dirname(__FILE__)
    Sequel.extension :migration
    db = Sequel.connect(ENV["DATABASE_URL"])
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "#{base_dir}/db/migrations", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "#{base_dir}/db/migrations")
    end
  end
  desc "Update sqlite blank file"
  task :blank_sqlite => "db/blank.sqlite"

  file "db/blank.sqlite" => ["db/create_schema.rb"] do
    require_relative 'db/create_schema'
    log = Logger.new(STDOUT)
    FileUtils.rm("db/blank.sqlite") if File.exist? "db/blank.sqlite"
    Buhos::SchemaCreation.create_db_from_scratch("sqlite://db/blank.sqlite", "en",log)
  end
end
