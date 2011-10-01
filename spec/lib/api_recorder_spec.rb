require 'spec_helper'
require 'api_recorder'


describe ApiRecorder do
  it "is a Faraday::Middleware" do
    ApiRecorder.superclass.should == Faraday::Middleware
  end

  it "has a run accessor" do
    result = TestRun.make
    ApiRecorder.run = result
    ApiRecorder.run.should == result
    ApiRecorder.run = nil
  end

  describe "call" do
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
      @recorder = ApiRecorder.new(@app)
      ApiRecorder.run = TestRun.make

      @url = stub("url",
        :path => Faker::Lorem.words(2).join("/"),
        :host => Faker::Lorem.words(3).join("."),
        :inferred_port => 81
      )

      @env = {
        :body => Faker::Lorem.words(10).join(" "),
        :method => "get",
        :url => @url
      }
    end
    
    after :each do
      ApiRecorder.run = nil
    end

    it "calls the @app with env" do
      @app.expects(:call).with(@env)
      @recorder.call(@env)
    end

    it "returns the result from the call" do
      result = {}
      @app.expects(:call).with(@env).returns(result)
      @recorder.call(@env).should == result
    end

    describe "creating the recorded ApiInteraction" do
      it "saves the record" do
        ApiInteraction.expects(:create)
        @recorder.call(@env)
      end

      it "sets path to url.path" do
        @recorder.call(@env)
        ApiInteraction.last.path.should == @url.path
      end
      
      it "sets ssl to true if url.inferred_port == 443" do
        @url.stubs(:inferred_port).returns(443)
        @recorder.call(@env)
        ApiInteraction.last.ssl.should be_true
      end
      
      it "sets ssl to true if url.inferred_port == 443" do
        @url.stubs(:inferred_port).returns(81)
        @recorder.call(@env)
        ApiInteraction.last.ssl.should be_false
      end
      
      it "sets host to url.host" do
        @recorder.call(@env)
        ApiInteraction.last.host.should == @url.host
      end
      
      it "sets host to url.host" do
        @recorder.call(@env)
        ApiInteraction.last.host.should == @url.host
      end      
      
      it "sets method to env[:method] if there's no method in the request body" do
        @env[:body] = "no_http_here"
        @recorder.call(@env)
        ApiInteraction.last.method.should == @env[:method]
      end

      it "sets method to the request body's method if present as method=value" do
        method = Faker::Lorem.words(1).to_s
        @env[:body] = "method=#{method}&abc=3"
        @recorder.call(@env)
        ApiInteraction.last.method.should == method
      end
      
      it "sets method to the request body's method if present as _method=value" do
        method = Faker::Lorem.words(1).to_s
        @env[:body] = "abc=3&_method=#{method}"
        @recorder.call(@env)
        ApiInteraction.last.method.should == method
      end
      
      it "does not use the response body to determine the method" do
        method = Faker::Lorem.words(1).to_s
        @env[:body] = "_method=#{method}"
        @app.on_call = Proc.new {|env| env[:body] = "method=badmethod123"}
        @recorder.call(@env)
        ApiInteraction.last.method.should == method
      end
      
      it "sets the status to the response status" do
        status = "300"
        @app.on_call = Proc.new {|env| env[:status] = status}
        @recorder.call(@env)
        ApiInteraction.last.response_status.should == status.to_i
      end
      
      it "sets the duration to the length of the call" do
        difference = 20
        start = Time.now
        Time.stubs(:now).returns(start, start + difference)
        @recorder.call(@env)
        ApiInteraction.last.duration.should == difference
      end
      
      it "saves the call inside the run's without_record_time block if there's a run" do
        # this is an imperfect spec because we rely on @recorder.call to be idempotent
        # whereas it could track state and not save the same env a second time
        # but since it happens to be idempotent (at least for now) 
        # we can verify that knocking out without_recording_time stops the record from getting saved
        # a very rough measure, but I can't figure out how to make the blocks work appropriately 
        ApiInteraction.expects(:create).once
        @recorder.call(@env)
        ApiRecorder.run.stubs(:without_recording_time)
        @recorder.call(@env)
      end
      
      it "saves the call if there's no run" do
        ApiRecorder.run = nil
        ApiInteraction.expects(:create)
        @recorder.call(@env)
      end
    end
  end
end