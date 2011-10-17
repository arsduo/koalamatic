require 'spec_helper'
require 'base/test_runner'

describe Koalamatic::Base::TestRunner do

  before :each do
    RSpec::Core::Runner.stubs(:run)
    RSpec.stubs(:configure)
    @runner = Koalamatic::Base::TestRunner.new
    @runner.stubs(:get_tests)
    @runner.stubs(:require_file)
  end

  it "has a logger" do
    @runner.should respond_to :logger
  end
  
  it "makes the test_run accessible as .run" do
    @runner.should respond_to :run
  end

  it "defines the SPEC_PATTERN" do
    Koalamatic::Base::TestRunner::SPEC_PATTERN.should == "**/*_spec.rb"
  end

  describe ".recorder_class" do
    it "returns the base ApiRecorder" do
      @runner.class.recorder_class.should == Koalamatic::Base::ApiRecorder
    end
  end

  describe ".test_run_class" do
    it "returns the base ApiRecorder" do
      @runner.class.test_run_class.should == Koalamatic::Base::TestRun
    end
  end
  
  describe "#new" do
    it "creates a new version of the test_run_class" do
      klass = stub("run class")
      Koalamatic::Base::TestRunner.stubs(:test_run_class).returns(klass)
      run = stub("run")
      klass.stubs(:new).returns(run)
      Koalamatic::Base::TestRunner.new.run.should == run
    end
  end

  describe "#execute" do
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

  describe "#setup_test_environment" do
    it "sets up the logger" do
      @runner.expects(:setup_logger)
      @runner.setup_test_environment
    end
    
    it "sets the appropriate recorder class's run to current run" do
      recorder = stub("class")
      recorder.expects(:run=).with(@runner.run)
      @runner.class.stubs(:recorder_class).returns(recorder)
      @runner.setup_test_environment
    end

    context "RSpec setup" do
      before :each do
        @config = stub("RSpec config block")
        @config.stubs(:after)
        @config.stubs(:before)
        @run = @runner.run
      end

      context "after :each test" do
        before :each do
          @example = stub("example", :exception => nil)
          @example.stubs(:rerun)
          @runner.stubs(:example).returns(@example)
        
          RSpec.stubs(:configure).yields(@config)
          @config.expects(:after).with(:each).yields        
        end
        
        it "it marks tests that don't need rerunning as done" do        
          # make the example available in the context of the runner
          @example.stubs(:should_rerun?).returns(false)
          @run.expects(:test_done).with(@example)
          @example.expects(:rerun).never
          @runner.setup_test_environment
        end
        
        context "for reruns" do
          it "it reruns tests that need to be rerun" do        
            # make the example available in the context of the runner
            @example.stubs(:should_rerun?).returns(true)
            @example.expects(:rerun)
            @runner.setup_test_environment
          end 
          
          it "pauses 5 seconds before rerunning the test" do        
            # make the example available in the context of the runner
            @example.stubs(:should_rerun?).returns(true)
            Kernel.expects(:sleep).with(5)
            @runner.setup_test_environment
          end
          
          it "does this without recording time" do
            @example.stubs(:should_rerun?).returns(true)
            # we test that it's inside the block by 
            # 1) verifying the method has been called
            # 2) verifying that deactivating the method stops the call
            @run.expects(:without_recording_time)
            @example.expects(:rerun).never
            Kernel.expects(:sleep).never
            @runner.setup_test_environment
          end
        end
      end

      it "marks each test as done after :suite" do
        @run.expects(:done)
        
        RSpec.stubs(:configure).yields(@config)
        @config.expects(:after).with(:suite).yields

        @runner.setup_test_environment
      end
    end

    it "loads the tests" do
      @runner.expects(:get_tests)
      @runner.setup_test_environment
    end
  end

  describe "#get_tests" do
    it "can't be called unless subclassed" do
      @runner.unstub(:get_tests)
      expect { @runner.get_tests }.to raise_exception(StandardError)
    end
  end

  describe "#publish_results" do
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
        Rails.logger.stubs(:warn)
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
        Rails.logger.expects(:warn)
        @runner.publish_results
      end

      it "rescues if an error occurs in publishing" do
        @runner.run.stubs(:publish_if_appropriate!).raises(Exception)
        expect { @runner.publish_results }.not_to raise_exception
      end

      it "prints a warning if an error occurs in publishing" do
        @runner.run.stubs(:publish_if_appropriate!).raises(Exception)
        Twitter.expects(:verify_credentials).returns(true)
        Rails.logger.expects(:warn)
        @runner.publish_results
      end
    end
  end
end