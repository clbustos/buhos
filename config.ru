require 'sinatra'
require 'rack/session/moneta'
#Sinatra::Application.default_options.merge!(
#  :run => false,
#  :env => :production
#)
require_relative 'app.rb'
disable :run
set :session_secret, "Secreto"
set :show_exceptions, true

if ENV['RACK_ENV'].to_sym == :production
  use Rack::Session::Moneta,
      key:            'revsist.investigacionpsicologia.cl',
      domain:         'revsist.investigacionpsicologia.cl',
      path:           '/',
      expire_after:   7*24*60*60, # one week
      secret:         ENV['PRODUCTION_SESSION_SECRET_KEY'],

      store:          Moneta.new(:LRUHash, {
          url:            'revsist.investigacionpsicologia.cl',
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

run Sinatra::Application
