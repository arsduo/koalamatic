require 'spec_helper'

describe ApiInteraction do
  it "is an ActiveRecord::Base" do
    ApiInteraction.superclass.should == ActiveRecord::Base
  end
end
