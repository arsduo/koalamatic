require 'spec_helper'
require 'rspec'
require 'monkey/rspec'

describe "RSpec patches" do
  describe RSpec::Core::Example do
    before :each do
      example_class = stub("example class", :metadata => {})
      example_class.metadata.stubs(:for_example)
      @example = RSpec::Core::Example.new(example_class, "test example", {})
      @exception = stub("exception")
    end
    
    it "makes the exception available" do
      @example.set_exception(@exception)
      @example.exception.should == @exception
    end

    it "has a verified_failure attribute" do
      result = stub("true")
      @example.verified_failure = result
      @example.verified_failure.should == result
    end
    
    it "has a failure_to_investigate attribute" do
      result = stub("true")
      @example.failure_to_investigate = result
      @example.failure_to_investigate.should == result
    end
    
    describe ".passed?" do
      it "is true if there's no exception" do
        @example.set_exception(nil)
        @example.passed?.should be_true
      end
      
      it "is false if there's an exception" do
        @example.set_exception(@exception)
        @example.passed?.should be_false
      end      
    end
    
    describe ".failed?" do
      it "is false if there's no exception" do
        @example.set_exception(nil)
        @example.failed?.should be_false
      end
      
      it "is true if there's an exception" do
        @example.set_exception(@exception)
        @example.failed?.should be_true
      end      
    end
    
    describe ".should_rerun?" do
      it "returns false if there's no exception" do
        @example.should_rerun?.should be_false    
      end
      
      context "for runs with exceptions" do
        before :each do
          begin; raise Exception; rescue Exception => @err; end;
          @example.set_exception(@err)
        end

        it "returns true if it hasn't been rerun before" do
          @example.should_rerun?.should be_true
        end
        
        it "returns false if the run has been rerun" do
          @example.stubs(:run).returns(true)
          @example.rerun
          @example.should_rerun?.should be_false
        end
      end
    end
    
    describe ".rerun" do
      it "has tests"
    end    
  end
  
  describe RSpec::Core::Reporter do
    it "makes test_user_api accessible" do
      RSpec::Core::Reporter.new.should respond_to(:pending_count)
    end
  end
end