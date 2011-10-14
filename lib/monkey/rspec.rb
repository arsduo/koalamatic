require 'facebook/error_comparison'

class RSpec::Core::Example
  attr_reader :exception, :original_exception

  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
  
  def should_rerun?
    @exception && !@tried_to_verify
  end
  
  def phantom_exception?
    @original_exception && !@exception
  end
  
  def different_exceptions?
    # this is almost the same as !verified_exception?
    # except that we want to require both exceptions be present
    @exception && @original_exception && !verified_exception?
  end
  
  def verified_exception?
    !!Facebook::ErrorComparison.same_error?(@original_exception, @exception)
  end
  
  def rerun
    unless @tried_to_verify
      # we'll want to compare the previous exception with the outcome of the second run
      @original_exception = @exception
      @exception = nil

      # don't get into an infinite loop
      @tried_to_verify = true
    
      # we use a new reporter because we don't want to mess up the test counts/reporting
      run(@example_group_instance, RSpec::Core::Reporter.new) 
    end
  end
end

class RSpec::Core::Reporter
  attr_reader :pending_count
end