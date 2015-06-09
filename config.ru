require 'rubygems'
require 'bundler'


Bundler.require(:default, ENV['RACK_ENV'] || 'development')
require_relative 'hplus'

use Rack::MethodOverride

run Transhumanity::Server
