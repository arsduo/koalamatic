module Koala
  def self.with_default_middleware
    # execute the actions with Koala's default middleware
    # useful for making calls during the analysis process (which we don't want recorded)
    original_middleware = http_service.faraday_middleware
    http_service.faraday_middleware = nil
    begin
      result = yield
    ensure
      http_service.faraday_middleware = original_middleware
    end
    
    result
  end
end

module KoalaTest
  class << self
    attr_accessor :test_user_api, :live_testing_user, :live_testing_friend
  end
end