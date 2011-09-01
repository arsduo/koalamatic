module Facebook
  module TestRunner
    class << self
      attr_reader :logger
    end
    
    def self.execute(&result_processing)
      run = TestRun.new
      setup_test_environment(run)
      test_files = load_tests
      # run the tests live
      RSpec::Core::Runner.run(test_files)
      run.done
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
        puts("Error in publishing! #{err.message}\n#{err.backtrace.join("\n")}")
      end
    end

    def self.setup_test_environment(run)
      setup_logger
      
      ENV["LIVE"] = "true"      
      RSpec.configure do |config|
        config.after :each do
          run.test_done(example)
        end
      end      

      # tests should be loaded after RSpec configuration
      load_tests
    end
    
    private
    
    # test case management
    def self.load_tests
      get_path
      identify_tests
    end

    def self.get_path
      g = Bundler.load.specs.find {|s| s.name == "koala"}  
      @path = File.join(g.full_gem_path, "spec") 
      $:.push(@path)
    end
    
    def self.identify_tests
      pattern = File.join(@path, "**/*_spec.rb")
      # run the test user suite last, since it deletes all the test users
      Dir.glob(pattern).sort {|a, b| a.match(/test/) ? 1 : -1}
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