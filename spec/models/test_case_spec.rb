require 'spec_helper'

describe TestCase do
  describe "#create_from_example" do
    before :each do
      @example = make_example
    end
    
    it "creates a new TestCase" do
      TestCase.create_from_example(@example).should be_a(TestCase)      
    end

    it "saves the new TestCase" do
      TestCase.create_from_example(@example).should_not be_a_new_record
    end
    
    it "sets the title to the example's full_description" do
      TestCase.create_from_example(@example).title.should == @example.full_description
    end
    
    context "when failing" do
      before :each do
        @example = make_example(true)
      end
      
      it "sets the failure_message to the exception's message" do
        TestCase.create_from_example(@example).failure_message.should == @example.exception.message
      end
      
      it "sets the backtrace to the exception's backtrace, joined on \\n" do
        TestCase.create_from_example(@example).backtrace.should == @example.exception.backtrace.join("\n")
      end
      
      it "sets failed to true" do
        TestCase.create_from_example(@example).failed.should be_true
      end
    end
    
    context "when passing" do
      it "sets the failure_message to nil" do
        TestCase.create_from_example(@example).failure_message.should be_nil
      end
      
      it "sets the backtrace to nil" do
        TestCase.create_from_example(@example).backtrace.should be_nil
      end
      
      it "sets failed to false" do
        TestCase.create_from_example(@example).failed.should be_false
      end
    end
  end
  
end