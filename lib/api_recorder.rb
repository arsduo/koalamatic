class ApiRecorder < Faraday::Middleware

  # there's only one test run happening at any time on any Koalamatic instance
  # (though there may be many test cases going in parallel)
  # so we can set this as a class variable without having to worry about threads
  attr_accessor :run
  
  def call(env)
    # read the request body first, since Faraday replaces it with the response
    request_body = env[:body]
    start_time = Time.now

    # make the request
    result = @app.call env

    # record the API call (to be analyzed later)
    url = env[:url]
    
    record_call = Proc.new do
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
    end
    # if we're inside a test run,
    # don't count time spent writing to the database toward total test execution
    run ? run.without_recording_time(&record_call) : record_call.call
    
    # pass it on to the next middleware
    result
  end
end