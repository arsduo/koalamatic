module Koalamatic
  module Base
    class TestCase < ActiveRecord::Base
      module ErrorStatus
        NONE = 0 # no errors
        UNKNOWN = 1 # pre-verification mostly
        PHANTOM = 2 # no error on rerun
        INCONSISTENT = 3 # two different errors
        VERIFIED = 4 # rerun produced the same error

        def self.from_example(example)
          if !example.original_exception
            NONE
          elsif example.phantom_exception?
            PHANTOM
          elsif example.different_exceptions?
            INCONSISTENT
          elsif example.verified_exception?
            VERIFIED
          else
            # this should never happen
            UNKNOWN
          end
        end
      end

      scope :verified_failures, where(:error_status => ErrorStatus::VERIFIED)
      scope :unverified_failures, where("error_status is not null").
                                  where(["error_status != ?", ErrorStatus::NONE]).
                                  where(["error_status != ?", ErrorStatus::VERIFIED])

      def self.create_from_example(example)
        create({
          :title => example.full_description,
          :failure_message => example.failed? ? example.original_exception.message : nil,
          :error_status => ErrorStatus.from_example(example),
          :backtrace => example.failed? ? example.original_exception.backtrace.join("\n") : nil
        })
      end
    end
  end
end