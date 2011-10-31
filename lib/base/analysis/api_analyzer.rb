require 'base/api_interaction'
module Koalamatic
  module Base
    module Analysis
      class ApiAnalyzer
        def self.interaction_class
          Koalamatic::Base::ApiInteraction
        end
      end
    end
  end
end