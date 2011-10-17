require 'spec_helper'
require 'facebook/error_comparison'

describe Facebook::ErrorComparison do
  include Facebook
  
  describe ".same_error?" do
    before :each do
      begin; raise Exception; rescue Exception => @err1; end
      begin; raise Exception; rescue Exception => @err2; end
      puts "E1: #{@err1.message}"
      puts "E2: #{@err2.message}"
    end
    
    context "validating the exceptions" do
      it "returns false if the first exception is blank" do
        @err1 = nil
        ErrorComparison.same_error?(@err1, @err2).should be_false
      end
    
      it "returns false if the second exception is blank" do
        @err2 = nil
        ErrorComparison.same_error?(@err1, @err2).should be_false
      end
    end
    
    context "comparing the backtraces" do
      it "returns false if the backtraces' first lines aren't equal" do
        @err1.stubs(:backtrace).returns([:a, :b])
        @err1.stubs(:backtrace).returns([:c, :b])
        ErrorComparison.same_error?(@err1, @err2).should be_false
      end
      
      it "returns true if the backtraces' first lines are equal (and all else is the same)" do
         @err1.backtrace[0] = @err2.backtrace[0]
         ErrorComparison.same_error?(@err1, @err2).should be_true         
      end
    end
    
    context "comparing the messages" do
      before :each do
        @err1.backtrace[0] = @err2.backtrace[0]
      end
      
      it "returns false if the messages aren't equal" do
        @err1.stubs(:message).returns(Faker::Lorem.words(10).join(" "))
        @err2.stubs(:message).returns(Faker::Lorem.words(10).join(" "))
        ErrorComparison.same_error?(@err1, @err2).should be_false
      end
   
      it "returns true if the messages are equal" do
        message = Faker::Lorem.words(10).join(" ")
        @err1.stubs(:message).returns(message)
        @err2.stubs(:message).returns(message)
        ErrorComparison.same_error?(@err1, @err2).should be_true
      end

      it "returns true if the messages are equal except for Ruby object_ids" do
        message = Faker::Lorem.words(10).join(" ")
        @err1.stubs(:message).returns(message + Object.new.inspect)
        @err2.stubs(:message).returns(message + Object.new.inspect)
        ErrorComparison.same_error?(@err1, @err2).should be_true        
      end

      it "returns true if the messages are equal except for Facebook user id" do
        message = Faker::Lorem.words(10).join(" ")
        @err1.stubs(:message).returns(message + "User #{rand(1000000).to_i}")
        @err2.stubs(:message).returns(message + "User #{rand(1000000).to_i}")
        ErrorComparison.same_error?(@err1, @err2).should be_true        
      end
      
      it "returns true if the messages are equal except for Ruby object_ids" do
        message = Faker::Lorem.words(10).join(" ")
        @err1.stubs(:message).returns(message + "application #{rand(1000000).to_i}")
        @err2.stubs(:message).returns(message + "application #{rand(1000000).to_i}")
        ErrorComparison.same_error?(@err1, @err2).should be_true        
      end
      
      it "returns true if the messages are equal except for combinations of the above" do
        message = Faker::Lorem.words(10).join(" ")
        @err1.stubs(:message).returns(message + "application #{rand(1000000).to_i} " + Object.new.inspect + " User #{rand(1000000).to_i}")
        @err2.stubs(:message).returns(message + "application #{rand(1000000).to_i} " + Object.new.inspect + " User #{rand(1000000).to_i}")
        ErrorComparison.same_error?(@err1, @err2).should be_true        
      end
    end    
  end
end