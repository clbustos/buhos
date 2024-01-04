# encoding: UTF-8

# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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



require "bundler/setup"
if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	# Windows doesn't have proper management of certificates for SSL. 
	# So, we have to user 'certified' gem to fix it
	require 'certified'
end


require 'sinatra'
require 'haml'
require 'logger'
require 'i18n'
require 'dotenv'
require 'digest/sha1'


require_relative("lib/buhos")
Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end

$test_mode=ENV['RACK_ENV'].to_s == "test"



installed_file= $test_mode ? "config/installed_test" : "config/installed"

if (!$test_mode and !File.exist?(installed_file)) or ENV['TEST_INSTALLER']
  load('installer.rb')
  Buhos::Installer.run!
  exit 1
end


if !$test_mode
  Dotenv.load("./.env")
end

set :session_secret, 'd290f527d209bd4cd94db2dbdecf29cabaa6499c04bcd83278e3863cd7b25490859df1173c2aa2fd2ede7db09b9208b588badf8298519c23fc16220b356c0029'

enable :logging, :dump_errors, :raise_errors, :sessions

configure :development do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
  set :show_exceptions, :after_handler
end

configure :production do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions
  set :show_exceptions, :after_handler
end

# this is required if you want to assume the default path
set :root, File.dirname(__FILE__)



# Arreglo a lo bestia para el force_encoding

unless "".respond_to? :force_encoding
  class String
    def force_encoding(s)
      self
    end
  end
end





Dir.glob("controllers/**/*.rb").each do |f|
  require_relative(f)
end


unless File.exist?("log")
  FileUtils.mkdir("log")
end

if $test_mode
  $log = Logger.new('log/test_app.log')
  $log_sql = Logger.new('log/test_app_sql.log')

else
  $log = Logger.new('log/app.log')
  $log_sql = Logger.new('log/app_sql.log')

end


#$log.info(Encoding.default_external)

require_relative 'model/init.rb'
require_relative 'model/models.rb'
require_relative 'lib/sinatra/partials.rb'


Dir.glob("model/*.rb").each do |f|
  require_relative(f)
end




helpers Sinatra::Partials
helpers DOIHelpers
helpers HTMLHelpers
helpers Buhos::Helpers
helpers Buhos::StagesMixin
helpers Buhos::ControllerReview


error 403 do
  haml :error403, escape_html:false
end
error 404 do
  haml :error404, escape_html:false
end


# INICIO


#require 'flamegraph'
get '/' do

  #Flamegraph.generate("test") do
    log.info("Parto en /")
    if session['user'].nil?
      log.info("/ sin id: basico")
      redirect url('/login')
    else
      @user=User[session['user_id']]
      haml :main, :escape_html=>false
    end
  #end
end

