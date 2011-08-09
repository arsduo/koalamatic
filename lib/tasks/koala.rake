require 'bundler'
require 'rspec'
require 'facebook_tests'

desc "Run the live tests and report out to the database and Twitter"
namespace :fb_tests do
  task :run => :environment do
    FacebookTests::Runner.execute do |test_run|
      puts "Failures: #{test_run.failure_count}"
      puts "Length: #{test_run.elapsed_time.seconds}"
    end
  end
end