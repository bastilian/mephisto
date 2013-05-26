ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

require 'coveralls'
Coveralls.wear!

MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]

require 'spec'
require 'spec/rails'
require 'ruby-debug'
require 'machinist'
require_relative 'blueprints'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.before(:each) { Sham.reset }  # Reset machinist before each test.
end

Debugger.start
