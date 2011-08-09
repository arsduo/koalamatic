require 'bundler'
require 'rspec'
require 'fb_tests'

desc "Run the live tests and report out to the database and Twitter"
namespace :fb_test do
  task :run => :environment do
    Facebook::TestRun.execute do |test_run|
      puts "Failures: #{test_run.failures.length}"
      puts "Length: #{test_run.elapsed_time.seconds}"
    end
  end
end