require 'koala'

module Koala
  module Facebook
    class TestUsers
      
      def delete_all
        puts "Deleting all users."
        list.each {|u| puts "Deleting user #{u.inspect}"; delete u}
      end
    end
  end
end