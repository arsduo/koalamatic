class RSpec::Core::Example
  attr_reader :exception

  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
end

class RSpec::Core::Reporter
  attr_reader :pending_count
end