module Facebook
  class TestRunner
    # this class is not thread-safe
    # because RSpec configurations aren't thread-safe
    attr_reader :logger, :run
    
    SPEC_PATTERN = "**/*_spec.rb"

    def initialize
      super
      @run = TestRun.new
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
        Kernel.warn("Error in publishing! #{err.message}\n#{err.backtrace.join("\n")}")
      end
    end

    def setup_test_environment
      setup_logger
      
      # run the tests live
      ENV["LIVE"] = "true"      
      run = @run
      RSpec.configure do |config|
        config.after :each do
          run.test_done(example)
        end

        config.after :all do
          run.done
        end
      end      

      # tests should be loaded after RSpec configuration
      get_tests
    end

    def get_tests
      add_load_path!
      identify_tests
    end
    
    private
    
    # test case management
    def add_load_path!
      g = Bundler.load.specs.find {|s| s.name == "koala"}  
      @path = File.join(g.full_gem_path, "spec")
      $:.push(@path) unless $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      @path
    end
    
    def identify_tests
      # run the test user suite last, since it deletes all the test users
      Dir.glob(File.join(@path, SPEC_PATTERN))#.sort {|a, b| a.match(/test/) ? 1 : -1}
    end
    
    def setup_logger
      # currently broken
      #loggerfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
      #@logger = Logger.new(loggerfile)
      #puts @logger.inspect
      #@logger.info("logging started")
      
      #@logfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
    end
  end
end