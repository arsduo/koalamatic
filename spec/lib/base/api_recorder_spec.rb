require 'spec_helper'
require 'base/api_recorder'

describe Koalamatic::Base::ApiRecorder do
  include Koalamatic::Base
  
  it "is a Faraday::Middleware" do
    ApiRecorder.superclass.should == Faraday::Middleware
  end
  
  describe ".interaction_class" do
    it "returns Koalamatic::Base::ApiInteraction" do
      ApiRecorder.interaction_class.should == Koalamatic::Base::ApiInteraction
    end
  end

  describe "common behavior" do
    before :each do
      @class = ApiRecorder
    end

    it_should_behave_like "an ApiRecorder class"
  end
end