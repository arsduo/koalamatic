require 'base/api_interaction'
require 'base/analysis/matchers/unknown_call_matcher'

module Koalamatic
  module Base
    module Analysis
      class ApiAnalyzer
        include Koalamatic::Base
        
        class << self
          attr_accessor :matchers
        end
        @matchers = []
        
        def self.interaction_class
          Koalamatic::Base::ApiInteraction
        end
      
        def self.analyze(interaction)
          raise ArgumentError, "ApiAnalyzer.analyze expects an ApiInteraction, got a #{interaction.class}" unless interaction.is_a?(ApiInteraction)        

          api_call = nil
          @matchers.each do |matcher| 
            break if api_call = matcher.test(interaction)
          end
          
          # return whatever match we find
          # or fall back to the UnknownCallMatcher if we have a gap in our coverage
          api_call || UnknownCallMatcher.test(interaction)
        end
      end # class ApiAnalyzer
    end # module Analysis
  end
end