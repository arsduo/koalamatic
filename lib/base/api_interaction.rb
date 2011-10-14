module Koalamatic
  module Base
    class ApiInteraction < ActiveRecord::Base
      # we expose these less because they're useful to access from outside
      # and more to commit to their availability since subclasses use them heavily
      attr_reader :env, :request_body, :url

      def initialize(call_details = {}, options = {})
        arg_check = [:env, :duration].inject([]) {|errs, p| errs << p unless call_details[p]; errs}
        raise ArgumentError, "Missing #{arg_check.join(",")} in ApiInteraction.create_from_call" if arg_check.length > 0

        @env = call_details[:env]
        @duration = call_details[:duration]
        @request_body = call_details[:request_body]
        @url = @env[:url]

        # initialize the AR with the appropriate attributes
        super(attributes_from_call, options)
      end

      private

      def attributes_from_call
        {
          :method => determine_method,
          #:request_body => request_body,
          :path => @url.path,
          :host => @url.host,
          #:query => url.query,
          :ssl => @url.inferred_port == 443,
          :duration => @duration,
          :response_status => @env[:status].to_i
        }
      end

      def determine_method
        # verbs other than GET and POST are sometimes conveyed in the body
        if @request_body.is_a?(String) && fake_method = @request_body.split("&").find {|param| param =~ /method=/}
          fake_method.split("=").last
        else
          @env[:method]
        end
      end
    end
  end
end
