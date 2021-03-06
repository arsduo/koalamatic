require 'bundler'
require 'rspec'
require 'facebook/test_runner'

namespace :fb do
  desc "Run the live tests and report out to the database and Twitter"
  task :run_tests => :environment do
    Facebook::TestRunner.new.execute do |test_run|
      #Facebook::TestRunner.logger.info "Failures: #{test_run.failure_count}"
      #Facebook::TestRunner.logger.info "Duration: #{test_run.elapsed_time.seconds}"
    end
  end
end