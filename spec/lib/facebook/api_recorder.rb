require 'spec_helper'
require 'facebook/api_recorder'

describe Facebook::ApiRecorder do
  
  describe "#interaction_class" do
    it "returns Facebook::ApiInteraction" do
      Facebook::ApiRecorder.interaction_class.should == Facebook::ApiInteraction
    end
  end
  
  describe ".call" do
    class FakeApp
      # a fake app object
      attr_accessor :on_call

      def call(env)
        if on_call
          # custom env processing
          on_call.call(env)
        else
          # replace the body with the response body
          env[:body] = Faker::Lorem.words(5).join(" ")
          env[:status] = 200
        end
      end
    end
    
    before :each do
      @app = FakeApp.new
      @recorder = Facebook::ApiRecorder.new(@app)
      Facebook::ApiRecorder.run = Facebook::TestRun.make
      Facebook::ApiInteraction.stubs(:create)
      
      @env = {
        :body => Faker::Lorem.words(10).join(" ")
      }
    end
    
    it "gets the primary_object using ObjectIdentifier" do
      Facebook::ObjectIdentifier.expects(:identify_object)
      @recorder.call(@env)
    end
    
    it "sets the env's primary_object" do
      obj = stub("identified object")
      Facebook::ObjectIdentifier.stubs(:identify_object).returns(obj)
      @recorder.call(@env)
      @env[:primary_object].should == obj
    end
    
    it "gets the object inside a without_recording_time block if there's a run" do
      # this is an imperfect spec because we rely on @recorder.call to be idempotent
      # whereas it could track state and not save the same env a second time
      # but since it happens to be idempotent (at least for now) 
      # we can verify that knocking out without_recording_time stops the call to identify_object
      Facebook::ObjectIdentifier.expects(:identify_object).once
      @recorder.call(@env)
      Facebook::ApiRecorder.run.stubs(:without_recording_time)
      @recorder.call(@env)
    end
    
    it "saves the call if there's no run" do
      Facebook::ApiRecorder.run = nil
      Facebook::ObjectIdentifier.expects(:identify_object)
      @recorder.call(@env)
    end    
  end    
end