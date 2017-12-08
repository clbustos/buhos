require 'dotenv'
Dotenv.load("./.env")

require 'rake'
require 'rspec/core/rake_task'
require 'gettext'

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

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    require "sequel"
    base_dir=File.dirname(__FILE__)
    Sequel.extension :migration
    db = Sequel.connect(ENV["DATABASE_URL"])
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, "#{base_dir}/model/migraciones", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, "#{base_dir}/model/migraciones")
    end
  end
end
