require 'spec_helper'
require 'base/api_analyzer'


describe Koalamatic::Base::Analysis::ApiAnalyzer do
  include Koalamatic::Base
  include Analysis

  it "has a matchers array" do
    ApiAnalyzer.matchers.should be_an(Array)
  end

  describe ".analyze" do
    before :each do
      @call = ApiInteraction.new
      @matcher1 = stub("matcher", :match => nil)
      @matcher2 = stub("matcher2", :match => nil)
      ApiAnalyzer.stubs(:matchers).returns([@matcher1, @matcher2])
    end
    
    it "errors if not provided an ApiInteraction" do
      expect { ApiAnalyzer.analyze(Object.new) }.to_raise ArgumentError
    end

    it "check the provided against all the matchers" do
      stub1.expects(:test).with(call)
      stub2.expects(:test).with(call)      
      ApiAnalyzer.analyze(@call)
    end

    context "if it finds a match" do
      before :each do
        @result = stub("result")
        @matcher1.expects(:test).returns(@result)
      end
      
      it "returns the match" do
        ApiAnalyzer.analyze(@call).should == @result
      end
      
      it "stops matching the results" do
        @matcher2.expects(:test).never
        ApiAnalyzer.analyze(@call)
      end
    end
    
    context "if it finds no match" do
      it "calls the unknown call matcher" do
        UnknownCallMatcher.expects(:test).with(@call)
        ApiAnalyzer.analyze(@call)
      end
      
      it "returns the result from the unknown call matcher" do
        result = stub("unknown call result")
        UnknownCallMatcher.stubs(:test).returns(result)
        ApiAnalyzer.analyze(@call).should == result
      end
    end
  end
end