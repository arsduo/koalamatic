module Koalamatic
  module Base
    class TestCase < ActiveRecord::Base
      belongs_to :test_run

      scope :failures, :conditions => {:failed => true}

      def self.create_from_example(example)
        create(
        :title => example.full_description,
        :failure_message => example.failed? ? example.exception.message : nil,
        :failed => example.failed?,
        :backtrace => example.failed? ? example.exception.backtrace.join("\n") : nil
        )
      end
    end
  end
end