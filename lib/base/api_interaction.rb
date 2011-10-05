module Koalamatic
  module Base
    class ApiInteraction < ActiveRecord::Base
      def self.create_from_call(details = {})
        interaction_details = attributes_from_call(details)
        self.create(interaction_details)
      end

      private 

      def self.attributes_from_call(details = {})
        arg_check = [:env, :duration].inject([]) {|errs, p| errs << p unless details[p]; errs}
        raise ArgumentError, "Missing #{arg_check.join(",")} in ApiInteraction.create_from_call" if arg_check.length > 0

        env = details[:env]
        duration = details[:duration]
        request_body = details[:request_body]
        url = env[:url]

        {    
          :method => determine_method(env, request_body),
          #:request_body => request_body,
          :path => url.path,
          :host => url.host,
          #:query => url.query,
          :ssl => url.inferred_port == 443,
          :duration => duration,
          :response_status => env[:status].to_i
        }
      end

      def self.determine_method(env, request_body = nil)
        # verbs other than GET and POST are sometimes conveyed in the body
        if request_body.is_a?(String) && fake_method = request_body.split("&").find {|param| param =~ /method=/}
          fake_method.split("=").last
        else
          env[:method]
        end    
      end
    end
  end
end
