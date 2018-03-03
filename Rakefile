# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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



desc "Test with output external coverage"
task :spec_cov=>[:before_spec, :spec, :after_spec]


task :before_spec do |t|
  sh %{cc-test-reporter before-build}

end


task :after_spec do |t|
  sh %{CC_TEST_REPORTER_ID=#{ENV['CC_TEST_REPORTER_ID']} cc-test-reporter after-build --exit-code 0}

end



RSpec::Core::RakeTask.new(:spec) do |t|

  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format documentation'
# t.rspec_opts << ' more options'
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
