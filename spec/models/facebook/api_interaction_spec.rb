require 'spec_helper'
require 'facebook/api_interaction'

describe Facebook::ApiInteraction do
  describe ".new" do
    it "sets primary_object to be that provided by the environment" do
      @env = make_env(:primary_object => stub("object"))
      Facebook::ApiInteraction.new(:env => @env, :duration => 3).primary_object.should == @env[:primary_object]
    end
  end
end
