module Facebook  
  class TestRun    
    attr_reader :failures, :tests, :start_time, :end_time

    def start
      @failures = []
      @tests = 0
      @start_time = Time.now
    end

    def test_done(example)
      @tests += 1
      @failures << example if example.failed?
    end

    def done
      @end_time = Time.now
    end

    def elapsed_time
      raise StandardError, "Tests aren't done running!" unless @end_time
      @end_time - @start_time
    end
    
    class << self
      def hook_rspec!
        run = Facebook::TestRun.new

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
      
      def execute(&block)
        run = hook_rspec!
        test_files = Facebook::TestHelper.load_tests
        RSpec::Core::Runner.run(test_files)
        yield run
      end
    end
  end

  module TestHelper
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