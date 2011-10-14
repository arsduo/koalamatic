require 'base/api_recorder'

module Facebook
  class ApiRecorder < Koalamatic::Base::ApiRecorder
    def call(env)
      outside_time do
        env[:primary_object] = Facebook::ObjectIdentifier.identify_object(env[:url])
      end
      super
    end

    def self.interaction_class
      Facebook::ApiInteraction
    end
  end
end