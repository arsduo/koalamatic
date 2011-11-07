require 'spec_helper'
require 'base/analysis/api_analyzer'

describe Koalamatic::Base::Analysis::ApiAnalyzer do
  include Koalamatic::Base
  include Koalamatic::Base::Analysis

  it "has a matchers array" do
    ApiAnalyzer.matchers.should be_an(Array)
  end

  describe ".analyze" do
    before :each do
      @call = ApiInteraction.new
      @matcher1 = stub("matcher1")
      @matcher1.stubs(:test)
      @matcher2 = stub("matcher2")
      @matcher2.stubs(:test)
      ApiAnalyzer.matchers << @matcher1
      ApiAnalyzer.matchers << @matcher2
    end
    
    it "errors if not provided an ApiInteraction" do
      expect { ApiAnalyzer.analyze(Object.new) }.to raise_exception(ArgumentError) 
    end

    it "check the provided against all the matchers" do
      @matcher1.expects(:test).with(@call)
      @matcher2.expects(:test).with(@call)      
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