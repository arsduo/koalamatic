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
    
    it "has a original_exception reader" do
      @example.should respond_to(:original_exception)
    end
    
    describe ".passed?" do
      before :each do
        @example.stubs(:run)
      end
      
      it "is true if there's no exception" do
        @example.set_exception(nil)
        @example.passed?.should be_true
      end
      
      it "is false if there's a phantom exception" do
        @example.set_exception(@exception)
        @example.rerun
        @example.passed?.should be_false
      end
      
      it "is false if there's a verified exception" do
        @example.set_exception(@exception)
        @example.rerun
        @example.set_exception(@exception.dup)
        @example.passed?.should be_false
      end     
    end
    
    describe ".failed?" do
      before :each do
        @example.stubs(:run)
      end
      
      it "is false if there's no exception" do
        @example.set_exception(nil)
        @example.failed?.should be_false
      end
      
      it "is true if there's a phantom exception" do
        @example.set_exception(@exception)
        @example.rerun
        @example.failed?.should be_true
      end
      
      it "is true if there's a verified exception" do
        @example.set_exception(@exception)
        @example.rerun
        @example.set_exception(@exception.dup)
        @example.failed?.should be_true
      end
    end
    
    describe ".should_rerun?" do
      it "returns false if there's no exception" do
        @example.should_rerun?.should be_false    
      end
      
      context "for runs with exceptions" do
        before :each do
          begin; raise Exception; rescue Exception => @err; end
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
    
    describe ".phantom_exception?" do
      before :each do
        @error = stub("error", :message => Faker::Lorem.words(3).join(" "))        
        @example.set_exception(@error)
      end
      
      it "returns true if there's an original exception but no repeat" do
        @example.stubs(:run).returns(true)
        @example.rerun
        @example.phantom_exception?.should be_true
      end
      
      it "returns false if there are no exceptions" do
        @example.phantom_exception?.should be_false        
      end
      
      it "returns false if both runs returned exceptions" do
        @error2 = stub("error", :message => Faker::Lorem.words(3).join(" "))        
        @example.stubs(:run).returns(false)
        @example.rerun
        @example.set_exception(@error2)
        @example.phantom_exception?.should be_false
      end
    end
    
    describe "different_exceptions?" do
      before :each do
        @error = stub("error", :message => Faker::Lorem.words(3).join(" "))        
        @error2 = stub("error2", :message => Faker::Lorem.words(3).join(" "))        
        @example.stubs(:run)
      end
      
      it "returns false if there were no exceptions" do
        @example.different_exceptions?.should be_false        
      end

      it "returns false if there was only one exceptions" do
        @example.set_exception(@error)
        @example.rerun
        @example.different_exceptions?.should be_false        
      end
      
      it "compares the two errors using the ErrorComparison module" do
        @example.set_exception(@error)
        @example.rerun
        @example.set_exception(@error2)
        Facebook::ErrorComparison.expects(:same_error?).with(@error, @error2)
        @example.different_exceptions?        
      end
      
      it "returns true if the two exceptions are different" do
        @example.set_exception(@error)
        @example.rerun
        @example.set_exception(@error2)
        Facebook::ErrorComparison.stubs(:same_error?).returns(false)
        @example.different_exceptions?        
      end
      
      it "returns false if the two exceptions are the same" do
        @example.set_exception(@error)
        @example.rerun
        @example.set_exception(@error2)
        Facebook::ErrorComparison.stubs(:same_error?).returns(true)
        @example.different_exceptions?        
      end
    end
    
    describe ".verified_exception?" do
      before :each do
        @example.stubs(:run)
      end
      
      it "compares the two errors using the ErrorComparison module" do
        Facebook::ErrorComparison.expects(:same_error?).with(@error, @error2)
        @example.verified_exception?        
      end
      
      it "returns true if ErrorComparison returns a truthy value" do
        result = stub("result")
        Facebook::ErrorComparison.stubs(:same_error?).returns(result)
        @example.verified_exception?.should be_true
      end
      
      it "returns true if ErrorComparison returns a falsy value" do
        Facebook::ErrorComparison.stubs(:same_error?).returns(nil)
        @example.verified_exception?.should be_false
      end      
    end
    
    describe "different_exceptions?" do
      before :each do
        @error = stub("error", :message => Faker::Lorem.words(3).join(" "))        
        @error2 = stub("error2", :message => Faker::Lorem.words(3).join(" "))        
        @example.stubs(:run)
      end
      
      it "returns false if there were no exceptions" do
        @example.different_exceptions?.should be_false        
      end

      it "returns false if there was only one exceptions" do
        @example.set_exception(@error)
        @example.rerun
        @example.different_exceptions?.should be_false        
      end
      
      it "returns true if the two exceptions are different" do
        @example.set_exception(@error)
        @example.rerun
        @example.set_exception(@error2)
        @example.stubs(:verified_exception?).returns(false)
        @example.different_exceptions?.should be_true    
      end
      
      it "returns false if the two exceptions are the same" do
        @example.set_exception(@error)
        @example.rerun
        @example.set_exception(@error2)
        @example.stubs(:verified_exception?).returns(true)
        @example.different_exceptions?.should be_false
      end
    end
    
    describe ".rerun" do
      before :each do
        @example.stubs(:run).returns(true)
        @error = stub("error", :message => Faker::Lorem.words(3).join(" "))
      end
      
      it "only runs once (e.g. no infinite loops)" do
        @example.expects(:run).once.returns(true)
        @example.rerun
        @example.rerun
      end
      
      it "clears the previous exception before the run" do
        @example.set_exception(@error)
        @example.rerun
        @example.exception.should be_nil
      end
      
      it "executes the second run with a different reporter to avoid messing up the counts" do
        reporter = stub("reporter")
        RSpec::Core::Reporter.stubs(:new).returns(reporter)
        @example.expects(:run).with(anything, reporter).returns(true)
        @example.rerun
      end
      
      it "makes the second exception available as .exception if one occurs" do
        @example.set_exception(@error)
        @error2 = stub("error2", :message => Faker::Lorem.words(3).join(" "))          
        @example.stubs(:run).returns(false)
        @example.rerun
        @example.set_exception(@error2)
        @example.exception.should == @error2
      end
    end    
  end
  
  describe RSpec::Core::Reporter do
    it "makes test_user_api accessible" do
      RSpec::Core::Reporter.new.should respond_to(:pending_count)
    end
  end
end