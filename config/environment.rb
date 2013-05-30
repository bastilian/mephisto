#encoding: UTF-8
Encoding.default_external = Encoding.default_internal = Encoding::UTF_8
# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

module Gem
  def self.source_index
    sources
  end

  def self.cache
    sources
  end

  SourceIndex = Specification

  class SourceList
    # If you want vendor gems, this is where to start writing code.
    def search( *args ); []; end
    def each( &block ); end
    include Enumerable
  end
end

if ENV["RAILS_ENV"] == "test"
  require 'coveralls'
  Coveralls.wear!('rails')
end

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# Make sure we a site-specific secret key file.
unless File.exists?(File.join(File.dirname(__FILE__),
                              'initializers/session_store.rb'))
  raise <<EOD
You need to run 'rake config/initializers/session_store.rb' to create a
secret key for encrypting session cookies.
EOD
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  config.autoload_paths += %W( #{RAILS_ROOT}/app/cachers #{RAILS_ROOT}/app/drops #{RAILS_ROOT}/app/filters )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  config.active_record.schema_format = :ruby

  config.active_record.observers = [:article_observer, :comment_observer]

  # Allow table tags in untrusted HTML, but block img tags to prevent
  # SRC attributes from being used in CSRF attacks.
  config.action_view.sanitized_allowed_tags = ['table', 'tr', 'td']
end

# Don't update this file, make custom tweaks in config/initializers/custom.rb, 
# or create your own file in config/initializers
