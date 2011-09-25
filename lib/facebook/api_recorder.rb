module Facebook
  class ApiRecorder < Faraday::Middleware
    def call(env)
      # read the request body first, since Faraday replaces it with the response
      request_body = env[:body]
      start_time = Time.now

      # make the request
      result = @app.call env

      # record the API call (to be analyzed later)
      url = env[:url]
      ApiCall.create(
        :method => env[:method],
        #:request_body => request_body,
        :path => url.path,
        :host => url.host,
        #:query => url.query,
        :ssl => url.inferred_port == 443,
        :duration => Time.now - start_time,
        :response_status => env[:status].to_i    
      )
      
      # pass it on to the next middleware
      result
    end
  end
end