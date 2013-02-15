source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'jquery-rails'
gem 'jbuilder'

gem 'mongo_mapper'
gem 'bson_ext' unless RUBY_PLATFORM =~ /java/
gem 'rufus-scheduler'

gem 'less-rails'
gem 'twitter-bootstrap-rails'

gem 'codemirror-rails'

gem 'formtastic'
gem 'formtastic-bootstrap'
gem 'crack'

group :assets do
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer', :platforms => :ruby
end

group :development, :test do
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'rspec-rails'

  gem 'growl' if RUBY_PLATFORM =~ /darwin/
  gem 'wdm', :platforms => [:mswin, :mingw], :require => false
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # To use debugger
  # gem 'debugger'

  gem 'thin'
end
