module Facebook
  module ErrorComparison
    
    def self.same_error?(exception1, exception2)      
      exception1 && exception2 && 
        exception1.backtrace.first == exception2.backtrace.first &&
        clean_message(exception1.message) == clean_message(exception2.message)
    end
    
    private 
    
    def self.clean_message(message)
      # exception messages are frozen
      msg = message.dup

      # remove IDs and other changeable issues
      if msg.match(/0x[0-9a-f]+\>/)
        # Ruby object IDs
        msg.gsub!(/:0x[0-9a-f]+/, "RUBY-OBJECT-ID")
      end
      
      # facebook object IDs
      msg.gsub!(/User [0-9]+/, "User FACEBOOK-USER-ID")
      msg.gsub!(/application [0-9]+/, "application FACEBOOK-APP-ID")
      
      msg
    end
  end
end