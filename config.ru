# encoding: utf-8
#\ -w 

require 'sinatra'
require 'dotenv'
require 'rack/session/moneta'



Dotenv.load("./.env") if File.exist? "./env" and ENV['RACK_ENV']!="test"

session_key         = ENV['PRODUCTION_SESSION_KEY']        || 'bd813bbefa24b9e7b0342034ade918dbd15500a4356accc5c144fedfa8f50cc91c71d81b336b921fb6367ce050e27bc51ff5822d2f04785856a9c5cfe26e019a'
session_domain      = ENV['PRODUCTION_SESSION_DOMAIN']     || 'localhost'
session_secret_key  = ENV['PRODUCTION_SESSION_SECRET_KEY'] || 'a2a7674d180fb2f55033bbf26fd0708117cb4351655dec6f9e0fbce40c9d30c928d01ee298773db589cf624ad23ee5c7ab42f03274665fcebbb11faf4dea3e9e'


#Sinatra::Application.default_options.merge!(
#  :run => false,
#  :env => :production
#)

disable :run
set :session_secret, "bd813bbefa24b9e7b0342034ade918dbd15500a4356accc5c144fedfa8f50cc91c71d81b336b921fb6367ce050e27bc51ff5822d2f04785856a9c5cfe26e019a"
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
#require 'rack-mini-profiler'

use Rack::ShowExceptions
#use Rack::MiniProfiler

if File.exist?("config/installed")
  require_relative 'app.rb'
  run Sinatra::Application
else
  require_relative 'installer.rb'
  run Buhos::Installer
end
