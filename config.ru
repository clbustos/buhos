require 'sinatra'
#Sinatra::Application.default_options.merge!(
#  :run => false,
#  :env => :production
#)
require './app'
disable :run
set :session_secret, "Secreto"
run Sinatra::Application
