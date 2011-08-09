module FacebookTests
  module Runner
    def self.execute(&result_processing)
      run = hook_rspec!
      test_files = load_tests
      RSpec::Core::Runner.run(test_files)
      yield run
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
  end
end