require 'spec_helper'
require 'facebook_test_runner'

describe Facebook::TestRunner do

  it "has a logger" do
    Facebook::TestRunner.should respond_to :logger
  end

  describe "#execute" do  
    before :each do
      RSpec::Core::Runner.stubs(:run)
      RSpec.stubs(:configure)
    end

    it "sets up the logger" do
      Facebook::TestRunner.expects(:setup_logger)
      Facebook::TestRunner.execute
    end
    
    it "creates a new run" do
      run = TestRun.new
      TestRun.expects(:new).returns(run)
      Facebook::TestRunner.execute      
    end
    
    it "sets up the test environment" do
      run = TestRun.new
      TestRun.stubs(:new).returns(run)
      Facebook::TestRunner.expects(:setup_test_environment).with(run)
      Facebook::TestRunner.execute      
    end
        
    it "sets ENV[\"LIVE\"] to true" do
      prev_env = ENV["LIVE"]
      ENV["LIVE"] = "false"
      Facebook::TestRunner.execute
      ENV["LIVE"].should be_true
      ENV["LIVE"] = prev_env
    end
  end
  
end