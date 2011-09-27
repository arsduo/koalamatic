require 'spec_helper'
require 'api_recorder'


describe ApiRecorder do
  it "is a Faraday::Middleware" do
    ApiRecorder.superclass.should == Faraday::Middleware
  end
  
  it "has a run accessor" do
    result = 2
    ApiRecorder.run = result
    ApiRecorder.run.should == result
  end
  
  
end