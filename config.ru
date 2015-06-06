require_relative 'hplus'
require 'pry'
require 'sinatra/base'
require 'sinatra/contrib'
require 'rest-client'
require 'httparty'
require 'json'
require 'redcarpet'

use Rack::MethodOverride

run Transhumanity::Server
