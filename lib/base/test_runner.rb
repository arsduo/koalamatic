require 'base/api_recorder'

module Koalamatic
  module Base
    class TestRunner
      # this class is not thread-safe
      # because RSpec configurations aren't thread-safe
      attr_reader :logger, :run

      SPEC_PATTERN = "**/*_spec.rb"

      def initialize
        @run ||= self.class.test_run_class.new
      end

      def execute(&result_processing)
        tests = setup_test_environment
        RSpec::Core::Runner.run(tests)
        yield @run if result_processing
        publish_results
      end

      def publish_results
        begin
          if Rails.env.production? && Twitter.verify_credentials
            # publish if it meets the publication criteria
            @run.publish_if_appropriate!
          end
        rescue Exception => err
          Rails.logger.warn("Error in publishing! #{err.message}\n#{err.backtrace.join("\n")}")
        end
      end

      def setup_test_environment
        setup_logger

        run = @run
        RSpec.configure do |config|
          config.before :suite do
            Rails.logger.info "Starting run for #{RSpec::world.example_count} examples."
          end

          config.after :each do
            unless example.should_rerun?
              # it passed, so we can count it immediately
              run.test_done(example)
            else
              # rerun the test run to see if we can replicate the error
              # this will rerun the after filter, saving the record
              example.rerun
            end
          end

          config.after :suite do
            Rails.logger.info "Run finished with #{@run.test_count} examples run, #{RSpec::world.reporter.pending_count} pending."
            Rails.logger.warn "MISMATCH!" if RSpec::world.example_count != @run.test_count + RSpec::world.reporter.pending_count
            run.done
          end
        end

        # tell ApiRecorder which run we're using so we can exclude database time
        self.class.recorder_class.run = run

        # tests should be loaded after RSpec configuration
        get_tests
      end

      def get_tests
        raise StandardError, "Cannot call get_tests on the Base::TestRunner -- must be called from subclass"
      end

      # we define these as methods because as constants they get evaluated on file load
      # before Rails has loaded the models
      def self.recorder_class
        Koalamatic::Base::ApiRecorder
      end

      def self.test_run_class
        TestRun #Koalamatic::Base::TestRun
      end

      private

      def identify_tests(path)
        Dir.glob(File.join(path, SPEC_PATTERN))
      end

      def setup_logger
        # currently broken
        #loggerfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
        #@logger = Logger.new(loggerfile)
        #puts @logger.inspect
        #@logger.info("logging started")

        #@logfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
      end

      def require_file(file)
        require file
      end
    end
  end
end