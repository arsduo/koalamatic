require 'spec_helper'
require 'facebook_test_runner'

describe Facebook::TestRunner do

  before :each do
    RSpec::Core::Runner.stubs(:run)
    RSpec.stubs(:configure)
    @runner = Facebook::TestRunner.new
  end

  it "has a logger" do
    @runner.should respond_to :logger
  end
  
  it "makes the test_run accessible as .run" do
    @runner.should respond_to :run
  end
  
  it "defines the SPEC_PATTERN" do
    Facebook::TestRunner::SPEC_PATTERN.should == "**/*_spec.rb"
  end
  
  describe ".new" do
    it "creates a run" do
      run = TestRun.make
      TestRun.stubs(:new).returns(run)
      Facebook::TestRunner.new.run.should == run
    end
  end

  describe ".execute" do
    it "sets up the test environment" do
      @runner.expects(:setup_test_environment)
      @runner.execute
    end

    it "runs the tests" do
      tests = [:my, :tests]
      @runner.expects(:setup_test_environment).returns(tests)
      RSpec::Core::Runner.expects(:run).with(tests)
      @runner.execute
    end

    it "yields the run if a block is provided" do
      run = @runner.run
      yielded = false
      @runner.execute do |yielded_run|
        yielded = (run == yielded_run)
      end
      yielded.should be_true
      @runner.execute
    end

    it "publishes the results" do
      @runner.expects(:publish_results)
      @runner.execute
    end
  end

  describe ".setup_test_environment" do
    it "sets up the logger" do
      @runner.expects(:setup_logger)
      @runner.setup_test_environment
    end

    it "sets ENV[\"LIVE\"] to true" do
      prev_env = ENV["LIVE"]
      ENV["LIVE"] = "false"
      @runner.setup_test_environment
      ENV["LIVE"].should be_true
      ENV["LIVE"] = prev_env
    end

    context "RSpec setup" do
      before :each do
        @config = stub("RSpec config block")
        @config.stubs(:after)
      end

      it "marks each test as done after :each" do
        run = @run
        RSpec.expects(:configure).yields(@config) do
          @config.expects(:after).with(:each).yields do |eval_context|
            example = stub("example")
            eval_context.stubs(:example).returns(example)
            run.expects(:test_done).with(example)
          end
        end
        @runner.setup_test_environment
        raise "not actually testing"
      end

      it "marks each test as done after :all" do
        run = @run
        RSpec.expects(:configure).yields(@config) do
          @config.expects(:after).with(:all).yields do |eval_context|
            run.expects(:done)
          end
        end
        @runner.setup_test_environment
        raise "not actually testing"
      end
    end

    it "loads the tests" do
      @runner.expects(:get_tests)
      @runner.setup_test_environment
    end
  end

  describe ".get_tests" do
    it "adds Koala's spec directory to the load path" do
      # this is a little less exact than I'd like, but it beats writing expectations against some very specific Bundler code
      @runner.get_tests
      $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}.should
    end

    it "doesn't add the path twice" do
      found = 0
      @runner.get_tests
      @runner.get_tests
      $:.each {|p| found += 1 if p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      found.should == 1
    end

    it "returns all the files" do
      tests = [:a, :b]
      # get the load path for this machine
      @runner.get_tests
      path = $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      Dir.stubs(:glob).with(File.join(path, Facebook::TestRunner::SPEC_PATTERN)).returns(tests)
      results = @runner.get_tests
      results.should == tests
    end
  end

  describe ".publish_results" do
    before :each do
      test_run_completed(:run => @runner.run)
      @runner.run.stubs(:publish_if_appropriate!)
      Twitter.stubs(:verify_credentials)
    end

    context "in dev/staging" do
      before :each do
        Rails.env.stubs(:production?).returns(false)
      end

      it "does not publish" do
        Twitter.expects(:verify_credentials).never
        Twitter.expects(:update).never
        @runner.publish_results
      end
    end

    context "in production" do
      before :each do
        Rails.env.stubs(:production?).returns(true)
      end

      it "checks credentials" do
        Twitter.expects(:verify_credentials).returns(false)
        @runner.publish_results
      end

      context "if credentials pass" do
        it "publishes the summary" do
          Twitter.expects(:verify_credentials).returns(true)
          @runner.run.expects(:publish_if_appropriate!)
          @runner.publish_results
        end
      end

      it "rescues if an error occurs in verifying credentials" do
        Twitter.stubs(:verify_credentials).raises(Exception)
        expect { @runner.publish_results }.not_to raise_exception
      end

      it "prints a warning if an error occurs in verifying credentials" do
        Twitter.stubs(:verify_credentials).raises(Exception)
        Kernel.expects(:warn)
        @runner.publish_results
      end

      it "rescues if an error occurs in publishing" do
        @runner.run.stubs(:publish_if_appropriate!).raises(Exception)
        Kernel.stubs(:warn)
        expect { @runner.publish_results }.not_to raise_exception
      end

      it "prints a warning if an error occurs in publishing" do
        @runner.run.stubs(:publish_if_appropriate!).raises(Exception)
        Twitter.expects(:verify_credentials).returns(true)
        Kernel.expects(:warn)
        @runner.publish_results
      end
    end
  end
end