source 'http://rubygems.org'

gem 'rails', '3.1.0.rc4'
gem 'arel', '2.1.4' # 2.1.5 is busted
gem "slim"

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem "koala", :git => "git://github.com/arsduo/koala.git", :branch => "v1.2"

# platform core
gem "rspec"
gem "rake"
group :development, :test do
  gem 'mysql2'
end
group :production do
  gem 'pg'
end

# Asset template engines
gem 'sass-rails', "~> 3.1.0.rc"
gem 'coffee-script'
gem 'uglifier'

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
