class RSpec::Core::Example
  attr_reader :exception

  def passed?
    @exception.nil?
  end

  def failed?
    !passed?
  end
end