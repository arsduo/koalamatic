require 'bundler'
require 'rspec'
require 'facebook_tests'

namespace :fb_tests do
  desc "Run the live tests and report out to the database and Twitter"
  task :run => :environment do
    FacebookTests::Runner.execute do |test_run|
      #FacebookTests::Runner.logger.info "Failures: #{test_run.failure_count}"
      #FacebookTests::Runner.logger.info "Duration: #{test_run.elapsed_time.seconds}"
    end
  end
end