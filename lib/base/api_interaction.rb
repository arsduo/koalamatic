module Koalamatic
  module Base
    class ApiInteraction < ActiveRecord::Base
      belongs_to :test_run
      belongs_to :api_call
      
      # we expose these less because they're useful to access from outside
      # and more to commit to their availability since subclasses use them heavily
      # to do: could these become protected attributes?
      attr_reader :env, :original_body, :url

      def initialize(call_details = {}, options = {})
        # this may be more magic than it's worth
        # it's nice to be able to use instance variables for env, body, etc.
        # but that could be accomplished, albeit less elegantly, by passing those values around
        # and wouldn't complicate the initialize method 
        if (@env = call_details[:env]) && (@duration = call_details[:duration])
          # we can be initialized either with details from a Faraday call, or directly
          # if we detect a call details (an environment and a duration), process them          
          @original_body = call_details[:request_body]
          @url = @env[:url]
          attrs = attributes_from_call.merge(:test_run => call_details[:run])
        else
          attrs = call_details
        end

        # initialize the AR with the appropriate attributes
        super(attrs, options)
      end


      private

      def attributes_from_call
        a = {
          :method => determine_method,
          :request_body => @original_body.to_yaml,
          :path => @url.path,
          :host => @url.host,
          :query_string => @url.query,
          :ssl => @url.inferred_port == 443,
          :duration => @duration,
          :response_status => @env[:status].to_i
        }
      end

      def determine_method
        # verbs other than GET and POST are sometimes conveyed in the body
        get_method_from_body(@original_body) || @env[:method]
      end
      
      def get_method_from_body(body)
        if body.is_a?(String) && string_method = body.split("&").find {|param| param =~ /method=/}
          string_method.split("=").last
        elsif body.is_a?(Hash)
          body[:method] || body[:_method] || body["method"] || body["_method"]
        end
      end
    end
  end
end
