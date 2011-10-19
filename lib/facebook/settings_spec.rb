require 'spec_helper'
require 'base/version_tracker'

# ensure app settings are properly set
describe "Koalamatic settings" do
  describe "VersionTracker" do
    it "tracks the Koala gem" do
      Koalamatic::Base::VersionTracker.test_gems.should include("koala")
    end
  end  
end