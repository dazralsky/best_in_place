require 'rubygems'
require 'bundler'

Bundler.require :default, :development

Combustion.initialize! :active_record
run Combustion::Application
