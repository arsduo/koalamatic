require 'spec_helper'
require 'base/version'

describe Koalamatic::Base::Version do
  include Koalamatic::Base
  
  it "has_many test_runs" do
    Version.should have_many(:test_runs)
  end
end
