# encoding: utf-8
#\ -w 

require 'sinatra'
require 'dotenv'
require 'rack/session/moneta'


# Only update css on development

 
if ENV['RACK_ENV'].to_sym == :development and !RUBY_PLATFORM=~/mingw32/
  require 'sass/plugin/rack'
  use Sass::Plugin::Rack
end

Dotenv.load("./.env") if File.exist? "./env" and ENV['RACK_ENV']!="test"

session_key         = ENV['PRODUCTION_SESSION_KEY']        || 'key'
session_domain      = ENV['PRODUCTION_SESSION_DOMAIN']     || 'localhost'
session_secret_key  = ENV['PRODUCTION_SESSION_SECRET_KEY'] || 'very_secret_key'


#Sinatra::Application.default_options.merge!(
#  :run => false,
#  :env => :production
#)

disable :run
set :session_secret, "Secreto"
set :show_exceptions, true

if ENV['RACK_ENV'].to_sym == :production
  use Rack::Session::Moneta,
      key:            session_key,
      domain:         session_domain,
      path:           '/',
      expire_after:   7*24*60*60, # one week
      secret:         session_secret_key,

      store:          Moneta.new(:LRUHash, {
          url:            session_domain,
          expires:        true,
          threadsafe:     true
      })
else
  use Rack::Session::Moneta,
      key:            'domain.name',
      domain:         '*',
      path:           '/',
      expire_after:   30*24*60*60, # one month
      secret:         ENV['DEV_SESSION_SECRET_KEY'],

      store:          Moneta.new(:LRUHash, {
          url:            'localhost',
          expires:        true,
          threadsafe:     true
      })
end

use Rack::ShowExceptions

if File.exist?("config/installed")
  require_relative 'app.rb'
  run Sinatra::Application
else
  require_relative 'installer.rb'
  run Buhos::Installer
end
