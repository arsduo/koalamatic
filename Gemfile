source 'http://rubygems.org'
 
gem 'rails', '3.1.1'
gem "slim"
gem 'thin'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

# use a version of Koala that cleans up after its test users
gem "koala", :git => "git://github.com/arsduo/koala.git", :ref => "013e58e2a98906e082e888f46e0f12ccdbc6d496"
gem "twitter"
gem "typhoeus"
gem "git"

gem "kaminari"

# platform core
RSPEC_VERSION = "~> 2.8.0.rc1" # used by rspec and rspec-rails
gem "rspec", RSPEC_VERSION
gem "rake"
gem 'mysql2'
gem 'pg'

# error notification
gem 'exception_notification', :require => 'exception_notifier'

# Asset template engines
gem 'sass-rails'
gem 'compass'
gem 'coffee-script'
gem 'uglifier'

gem 'jquery-rails'

group :test, :development do
  gem "ruby-debug19"
  gem "rspec-rails", RSPEC_VERSION
end

group :test do
  # Koalamatic testing
  # (as opposed to the tests we run against Facebook)
  gem 'machinist', '>= 2.0.0beta2'
  gem "mocha"
  gem "ZenTest"
  gem "faker"
  gem "remarkable", '>= 4.0.0alpha4'
  gem "benhutton-remarkable_activerecord"
  gem 'spork', '~> 0.9.0.rc'

  # javascript
  gem "jasmine"
  gem 'jasmine-headless-webkit'

  # guard and spork
  gem 'guard', :git => 'git://github.com/guard/guard.git', :branch => 'dev'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem "guard-jasmine-headless-webkit"

  # OS X integration
  gem "ruby_gntp"
  gem "rb-fsevent", "~> 0.4.3.1"
end

=begin
# spork comes first
guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'test' }, :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.+\.rb$})
  watch(%r{^config/initializers/.+\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb')
  watch('test/test_helper.rb')
end

=end

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'