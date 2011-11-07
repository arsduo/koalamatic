require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'remarkable/core'
  require 'remarkable/active_record'
  require 'machinist/active_record'
  require 'faker'
  
  RSpec.configure do |config|
    config.mock_with :mocha
  end

  # make sure Routes don't get reloaded inappropriately
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)
  
end

Spork.each_run do
  # This code will be run each time you run your specs.

  # load with each_run in case blueprints or other supporting code change
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  # reroute Rails logger to stdout
  Rails.logger = Logger.new(STDOUT)

  # Speed up integrated tests (will be useful when we hit view/integration testing)
  Sass::Plugin.options[:always_check] = false
  Sass::Plugin.options[:always_update] = false

  # never sleep (called in TestRunner)
  RSpec.configure do |config|
    config.before :suite do
      Kernel.stubs(:sleep)
    end
  end
end