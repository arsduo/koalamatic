module FacebookTests
  module Runner
    class << self
      attr_reader :logger
    end
    
    def self.execute(&result_processing)
      setup_logger
      run = hook_rspec!
      ENV["LIVE"] = "true"
      test_files = load_tests
      # run the tests live
      RSpec::Core::Runner.run(test_files, @logfile, @logfile)
      yield run
      publish_results(run)
    end

    def self.publish_results(run)
      begin
        if Rails.env.production? && Twitter.verify_credentials
          Twitter.update(run.summary)
        end
      rescue Exception
      end
    end

    # RSpec configuration
    def self.hook_rspec!
      run = TestRun.new

      RSpec.configure do |config|
        config.before :all do
          run.start
        end

        config.after :each do
          run.test_done(example)
        end

        config.after :all do
          run.done
        end
      end

      run
    end
    
    # test case management
    def self.load_tests
      get_path
      load_spec_helper
      identify_tests
    end

    def self.get_path
      g = Bundler.load.specs.find {|s| s.name == "koala"}  
      @path = File.join(g.full_gem_path, "spec") 
      $:.push(@path)
    end

    def self.load_spec_helper
      load File.join(@path, "spec_helper.rb")
    end

    def self.identify_tests
      pattern = File.join(@path, "**/*_spec.rb")
      Dir.glob(pattern)
    end
    
    private
    
    def self.setup_logger
      # currently broken
      #loggerfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
      #@logger = Logger.new(loggerfile)
      #puts @logger.inspect
      #@logger.info("logging started")
      
      @logfile = File.open(File.join(Rails.root, "log", "fb_tests.log"), "w")
    end
  end
end