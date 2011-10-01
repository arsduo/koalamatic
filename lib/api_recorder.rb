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
    url = env[:url]
    
    record_call = Proc.new do
      ApiInteraction.create(
        :method => determine_method(env, request_body),
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
    ApiRecorder.run ? ApiRecorder.run.without_recording_time(&record_call) : record_call.call
    
    # pass it on to the next middleware
    result
  end
  
  private
  
  def determine_method(env, request_body = nil)
    # verbs other than GET and POST are sometimes conveyed in the body
    if request_body.is_a?(String) && fake_method = request_body.split("&").find {|param| param =~ /method=/}
      fake_method.split("=").last
    else
      env[:method]
    end    
  end
end