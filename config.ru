require 'sinatra'
#Sinatra::Application.default_options.merge!(
#  :run => false,
#  :env => :production
#)
require_relative 'app.rb'
disable :run
set :session_secret, "Secreto"
set :show_exceptions, true

run Sinatra::Application
