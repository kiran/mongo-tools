source 'https://rubygems.org'

gem 'rails', '3.2.13'
gem 'jquery-rails'

gem 'mongo_mapper'
gem 'mongo', '>= 1.8.3'
gem 'bson_ext', '>= 1.8.3', :platforms => [:ruby, :mswin, :mingw]
gem 'rufus-scheduler'

gem 'codemirror-rails'

gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'crack'

gem 'settingslogic'

group :assets do
  gem 'twitter-bootstrap-rails'
  gem 'less-rails'

  # required for less
  gem 'therubyracer', :platforms => [:ruby]
  gem 'therubyrhino', :platforms => [:jruby]

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

  gem 'pry-rescue'
  gem 'pry-nav'
end

group :test do
  gem 'coveralls', require: false

  gem 'poltergeist'
  gem 'rspec-rails'
  gem 'spork'
end
