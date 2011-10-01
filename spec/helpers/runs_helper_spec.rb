require 'spec_helper'

describe RunsHelper do
  
  describe ".formatted_backtrace" do
    before :each do
      @case = TestCase.make
    end
    
    it "renders the right partial" do
      helper.expects(:render).with(has_entry(:partial => "backtrace"))
      helper.formatted_backtrace(@case)
    end

    it "passes in the test case" do
      helper.expects(:render).with(has_entry(:locals => has_entry(:test_case => @case)))
      helper.formatted_backtrace(@case)
    end
  end
  
  describe ".show_backtrace_divider?" do
    context "on the first line" do
      before :each do
        helper.stubs(:interesting_backtrace?).returns(false)
        helper.show_backtrace_divider?("abc")
      end

      it "returns false if the line is interesting" do
        helper.stubs(:interesting_backtrace?).returns(true)
        helper.show_backtrace_divider?("abc").should be_false
      end
    
      it "returns false if the line is uninteresting" do
        helper.stubs(:interesting_backtrace?).returns(false)
        helper.show_backtrace_divider?("abc").should be_false
      end
    end

    context "following an UNinteresting line" do
      before :each do
        helper.stubs(:interesting_backtrace?).returns(false)
        helper.show_backtrace_divider?("abc")
      end

      it "returns false if the line is interesting" do
        helper.stubs(:interesting_backtrace?).returns(true)
        helper.show_backtrace_divider?("abc").should be_false
      end
    
      it "returns false if the line is uninteresting" do
        helper.stubs(:interesting_backtrace?).returns(false)
        helper.show_backtrace_divider?("abc").should be_false
      end
    end

    context "following an interesting line" do
      before :each do
        helper.stubs(:interesting_backtrace?).returns(true)
        helper.show_backtrace_divider?("abc")
      end

      it "returns false if the line is interesting" do
        helper.stubs(:interesting_backtrace?).returns(true)
        helper.show_backtrace_divider?("abc").should be_false
      end
    
      it "returns true if the line is uninteresting" do
        helper.stubs(:interesting_backtrace?).returns(false)
        helper.show_backtrace_divider?("abc").should be_true
      end
    end
  end
  
  describe ".interesting_backtrace?" do
    it "returns true if the line =~ koalamatic" do
      helper.interesting_backtrace?("this is about koalamatic").should be_true
    end
    
    it "returns true if the line =~ koala" do
      helper.interesting_backtrace?("this is about koala").should be_true
    end
    
    it "returns false if the line isn't about koala/matic" do
      helper.interesting_backtrace?("this is about ruby and rails and rspec and systems and stuff").should be_false
    end    
  end
end
