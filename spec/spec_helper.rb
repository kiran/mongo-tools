require 'coveralls'
Coveralls.wear!('rails')

require 'spork'
# uncomment for debugging
# require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)

  require 'rspec/rails'
  require 'rspec/autorun'

  require 'capybara/rspec'
  require 'capybara/rails'
  require 'capybara/poltergeist'
  Capybara.javascript_driver = :poltergeist

  # patch for wait_until in Capybara 2.0+
  module Capybara
    class Session
      def wait_until(timeout = Capybara.default_wait_time)
        Capybara.send(:timeout, timeout, driver) { yield }
      end unless defined?(wait_until)
    end
  end

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  RSpec.configure do |config|
    config.infer_base_class_for_anonymous_controllers = false
    config.order = "random"
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
