require 'rubygems'
require 'bundler'

require_relative 'hplus'
Bundler.require(:default, ENV['RACK_ENV'] || 'development')

use Rack::MethodOverride

run Transhumanity::Server
