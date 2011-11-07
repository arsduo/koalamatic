require 'spec_helper'
require 'base/api_call'

describe Koalamatic::Base::ApiCall do
  include Koalamatic::Base
  
  it "has_many api_interactions" do
    ApiCall.should have_many(:api_interactions)
  end
end
