require 'base/version_tracker'

module Facebook
  module VersionTracker
    # mix the methods in at a class level
    include Koalamatic::Base::VersionTracker

    def self.test_gems
      ["koala"]
    end
  end
end