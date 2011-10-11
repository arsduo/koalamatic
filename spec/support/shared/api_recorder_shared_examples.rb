shared_examples_for "an ApiRecorder class" do
  it "has a run accessor" do
    run = stub("run")
    @class.run = run
    @class.run.should == run
    @class.run = nil
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
      @recorder = @class.new(@app)
      @class.run = Koalamatic::Base::TestRun.make

      @env = make_env
    end

    after :each do
      @class.run = nil
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
      it "creates the interaction with the Faraday env" do
        @class.interaction_class.expects(:create).with(has_entry(:env => @env))
        @recorder.call(@env)
      end

      it "creates the interaction with the original request body" do
        body = @env[:body]
        @app.on_call = lambda {|env| env[:body] = body * 3}
        @class.interaction_class.expects(:create).with(has_entry(:request_body => body))
        @recorder.call(@env)        
      end

      it "creates the interaction using the length of the call" do
        difference = 20
        start = Time.now
        Time.stubs(:now).returns(start, start + difference)
        # this calls Time.now and messes things up
        @class.run.stubs(:without_recording_time).yields
        @class.interaction_class.expects(:create).with(has_entries(:duration => difference))
        @recorder.call(@env)
      end

      it "saves the call inside the run's without_recording_time block if there's a run" do
        # this is an imperfect spec because we rely on @recorder.call to be idempotent
        # whereas it could track state and not save the same env a second time
        # but since it happens to be idempotent (at least for now) 
        # we can verify that knocking out without_recording_time stops the record from getting saved
        # a very rough measure, but I can't figure out how to make the blocks work appropriately 
        @class.interaction_class.expects(:create).once
        @recorder.call(@env)
        @class.run.stubs(:without_recording_time)
        @recorder.call(@env)
      end

      it "saves the call if there's no run" do
        @class.run = nil
        @class.interaction_class.expects(:create)
        @recorder.call(@env)
      end
    end
  end
end