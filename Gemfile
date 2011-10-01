source 'http://rubygems.org'
 
gem 'rails', '3.1.0'
gem "slim"
gem 'thin'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

# use a version of Koala that cleans up after its test users
gem "koala", :git => "git://github.com/arsduo/koala.git", :ref => "536e9f3d1f4ad1a4978e5728393e2356ebc47ef1"
gem "twitter"
gem "typhoeus"

gem "kaminari"

# platform core
gem "rspec"
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
  gem "rspec-rails", "~> 2.6"
end

group :test do
  # test content
  gem 'machinist', '>= 2.0.0beta2'
  gem "mocha"
  gem "autotest"
  gem "autotest-rails"
  gem "autotest-fsevent"
  gem "autotest-growl"
  gem "ZenTest"
  gem "faker"
  gem "remarkable", '>= 4.0.0alpha4'

  # javascript
  gem "jasmine"
end




# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'