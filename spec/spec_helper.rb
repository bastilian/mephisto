ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]

require 'coveralls'
Coveralls.wear_merged!('rails')

require 'spec'
require 'spec/rails'
require 'machinist'
require_relative 'blueprints'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.before(:each) { Sham.reset }  # Reset machinist before each test.
end