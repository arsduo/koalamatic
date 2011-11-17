require 'spec_helper'
require 'base/analysis/matchers/matcher'
require 'support/shared/matcher_shared_examples'
require 'base/api_call'
require 'facebook/object_identifier'

describe Koalamatic::Base::Analysis::Matcher do
  
  include Koalamatic::Base 
  include Koalamatic::Base::Analysis
  
  before :all do
    @klass = Matcher
  end
  
  it_should_behave_like "the Matcher class and its subclasses"

  # technically these are protected, but they're part of official interface for subclasses
  describe ".get_api_call" do
    it "raises an error, since it should be implemented in the subclasses" do
      expect { Matcher.send(:get_api_call, ApiInteraction.make) }.to raise_exception(NotImplementedError)
    end
  end

  describe ".create_api_call" do
    it "raises an error, since it should be implemented in the subclasses" do
      expect { Matcher.send(:create_api_call, ApiInteraction.make) }.to raise_exception(NotImplementedError)
    end
  end
end