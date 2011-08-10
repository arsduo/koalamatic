class ApiController < ApplicationController
  def start_run
    # start a test run if there hasn't been one in the last half hour
    logger.info("Starting!")
    last_run = TestRun.where("created_at < ?", Time.now - 30.minutes).limit(1).first
    logger.debug("Found #{last_run.inspect}")
    unless last_run
      logger.info("Starting tests.")
      system("bundle exec rake fb_tests:run")
      @result = :started
    else
      logger.debug("Too soon :(")
      @result = :too_soon
    end
    render :json => {:status => @result}
  end

end
