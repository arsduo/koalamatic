require 'base/api_interaction'
require 'facebook/object_identifier'

module Koalamatic
  module Base
    class ApiRecorder < Faraday::Middleware
      # there's only one test run happening at any time on any Koalamatic instance
      # (though there may be many test cases going in parallel)
      # so we can set this as a class variable without having to worry about threads
      class << self
        attr_accessor :run
      end

      def call(env)
        # read the request body first, since Faraday replaces it with the response
        request_body = env[:body]
        start_time = Time.now
        # make the request
        result = @app.call env

        # record the API call (to be analyzed later)
        outside_time do
          # if we're inside a test run,
          # don't count time spent writing to the database toward total test execution
          second_time = Time.now
          self.class.interaction_class.create({
            :duration => second_time - start_time,
            :env => env,
            :request_body => request_body
          })
        end

        # pass it on to the next middleware
        result
      end
      
      def self.interaction_class
        Koalamatic::Base::ApiInteraction
      end
            
      private
      
      def outside_time(&block)
        self.class.run ? self.class.run.without_recording_time(&block) : block.call
      end
    end
  end
end