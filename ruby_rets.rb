Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'lib', '*.rb')).each {|file| require "#{file}"}
require 'mechanize'
require 'pry'