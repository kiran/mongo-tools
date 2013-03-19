source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'jquery-rails'

gem 'mongo_mapper'
gem 'mongo', '>= 1.8.3'
gem 'bson_ext', '>= 1.8.3' unless RUBY_PLATFORM =~ /java/
gem 'rufus-scheduler'

gem 'codemirror-rails'

gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'crack'

group :assets do
  gem 'twitter-bootstrap-rails'
  gem 'less-rails'

  # required for less
  gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'guard-spork'

  # requries 'growlnotify' available here: http://growl.info/downloads
  gem 'growl' if RUBY_PLATFORM =~ /darwin/

  gem 'wdm', :platforms => [:mswin, :mingw], :require => false
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'rspec-rails'
end
