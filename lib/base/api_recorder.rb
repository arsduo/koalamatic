require 'base/api_interaction'

module Koalamatic
  module Base
    class ApiRecorder < Faraday::Middleware
      INTERACTION_CLASS = Koalamatic::Base::ApiInteraction

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
        record_call = Proc.new do
          INTERACTION_CLASS.create_from_call(
          :duration => Time.now - start_time,
          :env => env,
          :request_body => request_body
          )
        end
        # if we're inside a test run,
        # don't count time spent writing to the database toward total test execution
        ApiRecorder.run ? ApiRecorder.run.without_recording_time(&record_call) : record_call.call

        # pass it on to the next middleware
        result
      end
    end
  end
end