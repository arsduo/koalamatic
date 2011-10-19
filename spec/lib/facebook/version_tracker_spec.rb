require 'spec_helper'
require 'facebook/version_tracker'

describe Facebook::VersionTracker do
  include Facebook

  it "includes the Koalamatic::Base::VersionTracker module" do
    VersionTracker.included_modules.should include(Koalamatic::Base::VersionTracker)
  end

  describe ".test_gems" do
    it "returns [koala]" do
      VersionTracker.test_gems.should == ["koala"]
    end
  end

  describe "common behavior" do
    before :each do
      @tracker_class = VersionTracker
    end

    it_should_behave_like "a version tracker"
  end

end