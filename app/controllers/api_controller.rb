class ApiController < ApplicationController
  def start_run
    # start a test run if there hasn't been one in the last half hour
    unless last_run = TestRun.where("created_at < ?", Time.now - 30.minutes).limit(1).first
      system("bundle exec rake fb_tests:run")
      @result = :started
    else
      @result = :too_soon
    end
    render :json => {:status => @result}
  end

end
