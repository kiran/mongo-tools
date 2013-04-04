require 'spork'
# uncomment for debugging
# require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)

  require 'coveralls'
  Coveralls.wear!('rails')

  require 'rspec/rails'
  require 'rspec/autorun'

  require 'capybara/rspec'
  require 'capybara/rails'
  require 'capybara/poltergeist'

  Capybara.javascript_driver = :poltergeist

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
