require 'spec_helper'

describe ApiCall do
  it "is an ActiveRecord::Base" do
    ApiCall.superclass.should == ActiveRecord::Base
  end
end
