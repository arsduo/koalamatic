require 'spec_helper'
require 'base/test_case'

describe Koalamatic::Base::TestCase do
  include Koalamatic::Base
  
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
      
    it "sets error_status to the result of ErrorStatus.from_status" do
      status = -1 * rand(1000).to_i
      TestCase::ErrorStatus.stubs(:from_example).returns(status)
      TestCase.create_from_example(@example).error_status.should == status
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
    end
    
    context "when passing" do
      it "sets the failure_message to nil" do
        TestCase.create_from_example(@example).failure_message.should be_nil
      end
      
      it "sets the backtrace to nil" do
        TestCase.create_from_example(@example).backtrace.should be_nil
      end
    end
  end

  describe "scopes" do
    describe ".verified_failures" do
      it "only gets cases that have been verified" do
        TestCase.verified_failures.where_values_hash.should == {:error_status => TestCase::ErrorStatus::VERIFIED}
      end
    end

    describe ".unverified_failures" do
      it "doesn't get test cases with null status" do
        TestCase.unverified_failures.where_values.should include("error_status is not null")
      end

      it "doesn't get test cases with that passed" do
        TestCase.unverified_failures.where_values.should include("error_status != #{TestCase::ErrorStatus::NONE}")
      end

      it "doesn't get test cases whose errors were verified" do
        TestCase.unverified_failures.where_values.should include("error_status != #{TestCase::ErrorStatus::VERIFIED}")
      end
    end
  end

  describe Koalamatic::Base::TestCase::ErrorStatus do
    it "defines NONE = 0" do
      TestCase::ErrorStatus::NONE.should == 0
    end
    
    it "defines UNKNOWN = 1" do
      TestCase::ErrorStatus::UNKNOWN.should == 1
    end
    
    it "defines PHANTOM = 2" do
      TestCase::ErrorStatus::PHANTOM.should == 2
    end

    it "defines INCONSISTENT = 3" do
      TestCase::ErrorStatus::INCONSISTENT.should == 3
    end

    it "defines VERIFIED = 4" do
      TestCase::ErrorStatus::VERIFIED.should == 4
    end
    
    describe "#from_example" do
      before :each do
        @example = make_example(true)
      end
      
      it "returns NONE if there's no exception" do
        @example.stubs(:exception)
        TestCase::ErrorStatus.from_example(@example).should == TestCase::ErrorStatus::NONE
      end
      
      it "returns PHANTOM if it's a phantom" do
        @example.stubs(:phantom_exception?).returns(true)
        TestCase::ErrorStatus.from_example(@example).should == TestCase::ErrorStatus::PHANTOM
      end

      it "returns INCONSISTENT if the exceptions were different" do
        @example.stubs(:different_exceptions?).returns(true)
        TestCase::ErrorStatus.from_example(@example).should == TestCase::ErrorStatus::INCONSISTENT
      end
      
      it "returns VERIFIED if the exceptions were different" do
        @example.stubs(:verified_exception?).returns(true)
        TestCase::ErrorStatus.from_example(@example).should == TestCase::ErrorStatus::VERIFIED
      end
     
      it "returns UNKNOWN if somehow none of the others apply" do
        @example.stubs(:phantom_exception?).returns(false)
        @example.stubs(:different_exceptions?).returns(false)
        @example.stubs(:verified_exception?).returns(false)
        TestCase::ErrorStatus.from_example(@example).should == TestCase::ErrorStatus::UNKNOWN
      end 
    end
  end
end