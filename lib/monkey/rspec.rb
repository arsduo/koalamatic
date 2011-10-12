require 'facebook/error_comparison'

class RSpec::Core::Example
  attr_reader :exception
  attr_accessor :verified_failure, :failure_to_investigate

  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
  
  def should_rerun?
    @exception && !@tried_to_verify
  end
  
  def rerun
    unless @tried_to_verify
      # we'll want to compare the previous exception with the outcome of the second run
      previous_exception = @exception
      @exception = nil

      # don't get into an infinite loop
      @tried_to_verify = true
    
      # we use a new reporter because we don't want to mess up the test counts/reporting
      if run(@example_group_instance, RSpec::Core::Reporter.new) # if the run passes, it's not verified
        @failure_true = false
      else
        # see if we got the same error back, or if we got a different error
        if Facebook::ErrorComparison.same_error?(previous_exception, @exception)
          @verified_failure = true
        elsif @exception
          # we have an error, but it's not the same!
          Rails.logger.info "Got two different errors!\n#{previous_exception.message}\n#{@exception.message}"
          @failure_to_investigate = true
        end
      end
    end
  end
end

class RSpec::Core::Reporter
  attr_reader :pending_count
end