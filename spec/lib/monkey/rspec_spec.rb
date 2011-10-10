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
  end
  
  describe RSpec::Core::Reporter do
    it "makes test_user_api accessible" do
      RSpec::Core::Reporter.new.should respond_to(:pending_count)
    end
  end
end