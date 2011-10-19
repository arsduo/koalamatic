require 'spec_helper'
require 'base/version_tracker'

describe Koalamatic::Base::VersionTracker do
  include Koalamatic::Base

  # here we have to use a testing module, because we need to have some data in TEST_GEMS
  module TestVersionTracker
    include Koalamatic::Base::VersionTracker
  end

  it "defines a MissingGemError < StandardError" do
    VersionTracker::MissingGemError.superclass.should == StandardError
  end

  describe ".test_gems" do
    it "returns []" do
      TestVersionTracker.test_gems.should == []
    end
  end
  
  describe ".version_class" do
    it "returns Koalamatic::Base::Version" do
      TestVersionTracker.version_class.should == Koalamatic::Base::Version
    end
  end

  describe "common VersionTracker behavior" do
    before :each do
      @tracker_class = TestVersionTracker
    end

    it_should_behave_like "a version tracker"
  end
end