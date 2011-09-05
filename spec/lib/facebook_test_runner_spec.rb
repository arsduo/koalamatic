require 'spec_helper'
require 'facebook_test_runner'

describe Facebook::TestRunner do

  it "has a logger" do
    Facebook::TestRunner.should respond_to :logger
  end
  
  it "defines the SPEC_PATTERN" do
    Facebook::TestRunner::SPEC_PATTERN.should == "**/*_spec.rb"
  end
  
  before :each do
    RSpec::Core::Runner.stubs(:run)
    RSpec.stubs(:configure)
  end

  describe "#execute" do

    it "creates a new run" do
      TestRun.expects(:new)
      Facebook::TestRunner.execute
    end

    it "sets up the test environment using the new run" do
      run = TestRun.new
      TestRun.stubs(:new).returns(run)
      Facebook::TestRunner.expects(:setup_test_environment).with(run)
      Facebook::TestRunner.execute
    end

    it "runs the tests" do
      tests = [:my, :tests]
      Facebook::TestRunner.expects(:setup_test_environment).returns(tests)
      RSpec::Core::Runner.expects(:run).with(tests)
      Facebook::TestRunner.execute
    end

    it "yields the run if a block is provided" do
      run = TestRun.new
      TestRun.stubs(:new).returns(run)
      yielded = false
      Facebook::TestRunner.execute do |yielded_run|
        yielded = (run == yielded_run)
      end
      yielded.should be_true
      Facebook::TestRunner.execute
    end

    it "publishes the results" do
      run = TestRun.new
      TestRun.stubs(:new).returns(run)
      Facebook::TestRunner.expects(:publish_results).with(run)
      Facebook::TestRunner.execute
    end
  end

  describe "#setup_test_environment" do
    before :each do
      @run = TestRun.new
    end

    it "sets up the logger" do
      Facebook::TestRunner.expects(:setup_logger)
      Facebook::TestRunner.setup_test_environment(@run)
    end

    it "sets ENV[\"LIVE\"] to true" do
      prev_env = ENV["LIVE"]
      ENV["LIVE"] = "false"
      Facebook::TestRunner.setup_test_environment(@run)
      ENV["LIVE"].should be_true
      ENV["LIVE"] = prev_env
    end

    context "RSpec setup" do
      before :each do
        @config = stub("RSpec config block")
        @config.stubs(:after)
      end

      it "marks each test as done after :each" do
        RSpec.expects(:configure).yields(@config) do
          @config.expects(:after).with(:each).yields do |eval_context|
            example = stub("example")
            eval_context.stubs(:example).returns(example)
            @run.expects(:test_done).with(example)
          end
        end
        Facebook::TestRunner.setup_test_environment(@run)
        raise "not actually testing"
      end

      it "marks each test as done after :all" do
        RSpec.expects(:configure).yields(@config) do
          @config.expects(:after).with(:all).yields do |eval_context|
            @run.expects(:done)
          end
        end
        Facebook::TestRunner.setup_test_environment(@run)
        raise "not actually testing"
      end
    end

    it "loads the tests" do
      Facebook::TestRunner.expects(:get_tests)
      Facebook::TestRunner.setup_test_environment(@run)
    end
  end

  describe "#get_tests" do
    it "adds Koala's spec directory to the load path" do
      # this is a little less exact than I'd like, but it beats writing expectations against some very specific Bundler code
      Facebook::TestRunner.get_tests
      $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}.should
    end

    it "doesn't add the path twice" do
      found = 0
      Facebook::TestRunner.get_tests
      Facebook::TestRunner.get_tests
      $:.each {|p| found += 1 if p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      found.should == 1
    end

    it "returns all the files" do
      tests = [:a, :b]
      # get the load path for this machine
      Facebook::TestRunner.get_tests
      path = $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      Dir.stubs(:glob).with(File.join(path, Facebook::TestRunner::SPEC_PATTERN)).returns(tests)
      results = Facebook::TestRunner.get_tests
      results.should == tests
    end
  end

  describe "#publish_results" do
    before :each do
      @run = test_run_completed
      Twitter.stubs(:update)
      Twitter.stubs(:verify_credentials)
    end

    context "in dev/staging" do
      before :each do
        Rails.env.stubs(:production?).returns(false)
      end

      it "does not publish" do
        Twitter.expects(:verify_credentials).never
        Twitter.expects(:update).never
        Facebook::TestRunner.publish_results(@run)
      end
    end

    context "in production" do
      before :each do
        Rails.env.stubs(:production?).returns(true)
      end

      it "checks credentials" do
        Twitter.expects(:verify_credentials).returns(false)
        Facebook::TestRunner.publish_results(@run)
      end

      context "if credentials pass" do
        it "publishes the summary" do
          Twitter.expects(:verify_credentials).returns(true)
          summary = :a
          @run.stubs(:summary).returns(summary)
          Twitter.expects(:update).with(summary)
          Facebook::TestRunner.publish_results(@run)
        end
      end

      it "rescues if an error occurs in verifying credentials" do
        Twitter.stubs(:verify_credentials).raises(Exception)
        expect { Facebook::TestRunner.publish_results(@run) }.not_to raise_exception
      end

      it "prints a warning if an error occurs in verifying credentials" do
        Twitter.stubs(:verify_credentials).raises(Exception)
        Kernel.expects(:warn)
        Facebook::TestRunner.publish_results(@run)
      end

      it "rescues if an error occurs in verifying credentials" do
        Twitter.stubs(:update).raises(Exception)
        expect { Facebook::TestRunner.publish_results(@run) }.not_to raise_exception
      end

      it "prints a warning if an error occurs in publishing" do
        Twitter.stubs(:update).raises(Exception)
        Twitter.expects(:verify_credentials).returns(true)
        Kernel.expects(:warn)
        Facebook::TestRunner.publish_results(@run)
      end
    end
  end
end