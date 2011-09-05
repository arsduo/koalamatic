module Facebook
  module TestRunner
    class << self
      attr_reader :logger
    end
    
    SPEC_PATTERN = "**/*_spec.rb"
    
    def self.execute(&result_processing)
      run = TestRun.new
      test_files = setup_test_environment(run)
      RSpec::Core::Runner.run(test_files)
      yield run if result_processing
      publish_results(run)
    end

    def self.publish_results(run)
      begin
        if Rails.env.production? && Twitter.verify_credentials
          puts("Publishing results: #{run.summary}")
          Twitter.update(run.summary)
        end
      rescue Exception => err
        puts "error!"
        Kernel.warn("Error in publishing! #{err.message}\n#{err.backtrace.join("\n")}")
      end
    end

    def self.setup_test_environment(run)
      setup_logger
      
      # run the tests live
      ENV["LIVE"] = "true"      
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

    def self.get_tests
      add_load_path
      identify_tests
    end
    
    private
    
    # test case management
    def self.add_load_path
      g = Bundler.load.specs.find {|s| s.name == "koala"}  
      @path = File.join(g.full_gem_path, "spec")
      $:.push(@path) unless $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      @path
    end
    
    def self.identify_tests
      # run the test user suite last, since it deletes all the test users
      Dir.glob(File.join(@path, SPEC_PATTERN))#.sort {|a, b| a.match(/test/) ? 1 : -1}
    end
    
    def self.setup_logger
      # currently broken
      #loggerfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
      #@logger = Logger.new(loggerfile)
      #puts @logger.inspect
      #@logger.info("logging started")
      
      #@logfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
    end
  end
end