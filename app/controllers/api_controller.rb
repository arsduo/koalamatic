class ApiController < ApplicationController
  def start_run
    # start a test run if there hasn't been one in the designated interval
    if Facebook::TestRun.time_for_next_run?
      logger.info("Starting tests.")
      Kernel.system("bundle exec rake fb:run_tests &")
      @result = :started
    else
      logger.info("Too soon :( #{Facebook::TestRun.last.inspect}")
      @result = :too_soon
    end
    render :json => {:status => @result}
  end

end
