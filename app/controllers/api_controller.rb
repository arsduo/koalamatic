class ApiController < ApplicationController
  def start_run
    # start a test run if there hasn't been one in the last half hour
    last_run = TestRun.where("created_at > ?", Time.now - 20.minutes).limit(1).first
    if !last_run
      logger.info("Starting tests.")
      system("bundle exec rake fb_tests:run &")
      @result = :started
    else
      logger.info("Too soon :( #{last_run.inspect}")
      @result = :too_soon
    end
    render :json => {:status => @result}
  end

end
